# 공용 스킬 단일소스 (dogany framework skills)

이 폴더(`dogany-project/skills/`)는 dogany 프레임워크의 **공용(디폴트) 스킬 단일소스**다. 모든 에이전트는 각자의 `.claude/skills/` 아래에서 이 폴더의 스킬을 **심링크**로 공유한다. 여기 한 곳을 고치면 전 에이전트에 동시 반영된다(복제본 금지).

## 구성

공용 스킬(이 폴더):
- skill-creator, memory-search, cron-register, proactive-push, reminder, user-onboarding

디폴트 풀세트 (신규 민팅이 자동 상속, DGN-036 §12):
- skill-creator / memory-search / cron-register / task-update / user-onboarding / proactive-push
- OPTIONAL(필요 시만): reminder / diet-log / workout-log

고유 스킬:
- 각 에이전트 `.claude/skills/` 아래 **실파일**(심링크 아님). 그 에이전트가 소유하고, 공개 레포에서 자연 제외된다. 예: 아그(main)의 appointment-log / diet-log / relationship / task-update / workout-log, 메탈(dev)의 dev 전용 스킬.

## CRUD 거버넌스

공용 스킬은 누가 고치느냐를 둘로 가른다 — 무엇을 담을지(내용)와 어떻게 배선할지(구조):

- 내용 CRUD = main agent(아그) 단일 창구. 공용 스킬의 SKILL.md 본문·스크립트를 일상적으로 추가/수정/삭제하는 것은 아그가 단일 창구로 처리한다. 다른 에이전트(area 등)는 직접 고치지 말고 변경을 아그에게 요청한다(쓰기권한 단일화 → 드리프트 방지).
- 인프라/구조 = dev-agent(메탈) 소관. 심링크 배선, 디폴트 세트 변경, 베이스라인 정합, 거버넌스 자체, 폐기된 정책 교정 같은 구조 변경은 메탈이 처리한다(헌법·훅·settings·구조가 메탈 역할).
- 요약: 무엇을 담을지 = 아그, 어떻게 배선/구조화할지 = 메탈.

## env / 토큰 표준

공용 스킬의 스크립트는 토큰·chat_id·API 키를 **평문으로 박지 않는다**. 각 에이전트 인스턴스의 `.env`에서 읽는다:

- 경로는 `SCRIPT_DIR` 기준 동적으로 해소한다(에이전트마다 `<workspace>/runtime/.env` 또는 `<workspace>/.telegram_bot/.env`로 다르므로). 절대경로·특정 에이전트 경로를 박지 않는다.
- 인스턴스 `.env`에 값이 없으면 전역 `~/telegram_bot/.env`로 폴백한다.
- 이렇게 하면 같은 공용 스크립트가 에이전트별 봇/토큰으로 알아서 동작한다(봇 섞임 없음).

## 발동(triage)

런타임 자동 디스커버리(스킬 description 매칭 → Skill 도구 호출) + 각 에이전트 CLAUDE.md/RULES의 스킬 트리거 규칙, 두 겹으로 발동한다. description만으로 발동이 미보장된 이력이 있어 헌법 트리거를 보강한다. (find-skills는 발동이 아니라 "원하는 스킬을 찾아 설치"하는 별개 디스커버리 도구다.)

## 관련 티켓
- DGN-058 (스킬 구조 재설계 — 이 문서의 근거)
- DGN-036 §12 (디폴트/옵셔널 분류)
- DGN-006 (공개 레포엔 공용 프레임워크 스킬만 배포)
