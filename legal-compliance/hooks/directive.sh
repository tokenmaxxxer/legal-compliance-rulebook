#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 이 스펙/처리가 법·규제를 통과하는가"
USE_WHEN="USE_WHEN: 개인정보·라이선스·계약이 걸릴 때"
PRODUCES=$'PRODUCES (required record fields): compliance verdict, applicable regulation list, required mitigations\n\nWRITE_SCOPE: []'
HAND_OFF=$'HAND-OFF: 전사 리스크 노출 규모 판단은 → risk-management\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above,\nstop and hand off per the arrow — do not silently absorb another role\'s\nscope. Record the hand-off point in this role\'s record before opening the\nnext role\'s session.'
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
