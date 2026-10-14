#!/bin/bash
set -e

FLAG_LENGTH=${#GZCTF_FLAG}
MID_POINT=$((FLAG_LENGTH / 2))

FIRST_PART="${GZCTF_FLAG:0:MID_POINT}"
SECOND_PART="${GZCTF_FLAG:MID_POINT}"

mkdir -p /app/review_artifacts /app/skills/workflow_validator/fixtures
TRACE_FILE="/app/review_artifacts/.trace.bundle"
printf 'review-seed\nhold-line\n%s\n' "$SECOND_PART" > "$TRACE_FILE"
chmod 444 "$TRACE_FILE"
unset GZCTF_FLAG

SKILL_FILE="/app/skills/evidence_archive/SKILL.md"

ESCAPED_FIRST_PART=$(echo "$FIRST_PART" | sed 's/[\/&]/\\&/g')
sed -i "s/flagpart1/${ESCAPED_FIRST_PART}/g" "$SKILL_FILE"
chmod 444 "$SKILL_FILE"

if command -v su-exec >/dev/null 2>&1; then
    exec su-exec appuser python -m uvicorn main:app --host 0.0.0.0 --port 8000
elif command -v gosu >/dev/null 2>&1; then
    exec gosu appuser python -m uvicorn main:app --host 0.0.0.0 --port 8000
else
    exec su -s /bin/bash -c "python -m uvicorn main:app --host 0.0.0.0 --port 8000" appuser
fi
