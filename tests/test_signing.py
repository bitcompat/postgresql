#!/usr/bin/env python3
"""Exercise the workflow's shell steps with registry-specific digests."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap

WORKFLOW = Path(__file__).resolve().parents[1] / '.github/workflows/build.yaml'


def step_script(name):
    section = WORKFLOW.read_text().split(f'      - name: {name}\n', 1)[1]
    lines = section.split('        run: |\n', 1)[1].splitlines()
    script = []
    for line in lines:
        if line and not line.startswith('          '):
            break
        script.append(line)
    return textwrap.dedent('\n'.join(script))


with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp)
    crane = path / 'crane'
    crane.write_text('''#!/bin/bash
set -eu
[[ "${FAIL_CRANE:-0}" != 1 ]] || exit 7
[[ "${BAD_DIGEST:-0}" != 1 ]] || { echo 'invalid'; exit 0; }
case "$2" in
  ghcr.io/*) digit=a ;;
  public.ecr.aws/*) digit=b ;;
  *) exit 8 ;;
esac
printf '%s@sha256:' "$2"
for _ in {1..64}; do printf '%s' "$digit"; done
printf '\n'
''')
    cosign = path / 'cosign'
    cosign.write_text('#!/bin/bash\nprintf "%s\\n" "$@" > "$SIGNED_ARGS"\n')
    for executable in (crane, cosign):
        executable.chmod(0o755)
    tags = ['ghcr.io/bitcompat/postgresql:18-trixie',
            'public.ecr.aws/bitcompat/postgresql:18-trixie']
    env = dict(os.environ, PATH=f'{path}:{os.environ["PATH"]}',
               DOCKER_METADATA_OUTPUT_JSON=json.dumps({'tags': tags}),
               GITHUB_OUTPUT=str(path / 'output'), SIGNED_ARGS=str(path / 'signed'))
    flatten = step_script('Flatten images')
    sign = step_script('Sign image with a key')
    for script in (flatten, sign):
        subprocess.run(['bash', '-n'], input=script, text=True, check=True)
    subprocess.run(['bash', '-c', flatten], env=env, check=True)
    env['DIGEST'] = (path / 'output').read_text().strip().split('=', 1)[1]
    subprocess.run(['bash', '-c', sign], env=env, check=True)
    assert (path / 'signed').read_text().splitlines() == [
        'sign', '--yes', '--key', 'env://COSIGN_PRIVATE_KEY',
        tags[0] + '@sha256:' + 'a' * 64,
        tags[1] + '@sha256:' + 'b' * 64,
    ]
    for failure in ('FAIL_CRANE', 'BAD_DIGEST'):
        (path / 'output').unlink(missing_ok=True)
        result = subprocess.run(['bash', '-c', flatten], env=dict(env, **{failure: '1'}))
        assert result.returncode != 0, failure
        assert not (path / 'output').exists(), failure
    print('PASS: each registry signs its own digest; flatten errors and invalid digests stop signing')
