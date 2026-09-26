#!/usr/bin/env bash
cat >/dev/null
if [[ -x bin/verify ]]; then
  bin/verify >/tmp/riff-room-verify.log 2>&1 || true
fi
echo '{ "additional_context": "bin/verify ran after the edit. Read /tmp/riff-room-verify.log if the suite failed." }'
