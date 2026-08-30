/**
 * POSCO KRY TOOLBOX — 사이트 목록 설정
 *
 * 새 웹사이트를 추가하려면:
 *   1) index.html과 같은 위치에 새 폴더를 만들고, 그 안에 index.html을 넣는다.
 *      예) ./zabbix-viewer/index.html
 *   2) 아래 SITES 배열에 객체 하나를 추가한다.
 *   3) 저장하면 끝. 코드 수정 없이 버튼이 자동으로 생성된다.
 *
 * 필드 설명
 *   id    : 카드 좌상단에 표시되는 짧은 코드 (예: "01", "NET-A"). 비워도 됨.
 *   name  : 버튼에 표시될 사이트 이름
 *   desc  : 한 줄 설명
 *   path  : index.html이 들어있는 폴더 이름 (상대 경로)
 */
const SITES = [
  {
    id: "CountMin",
    name: "약속시간 계산기",
    desc: "약속한 시간이 몇분 남았을까?",
    path: "CountMin",
  },
  {
    id: "CheckList",
    name: "Safety rating check",
    desc: "현장작업 안전등급 미리보기",
    path: "CheckList",
  },
  // 여기 아래에 계속 추가하면 됩니다. 예시:
  // {
  //   id: "NET-01",
  //   name: "장비 상태 대시보드",
  //   desc: "Zabbix 알림 요약 뷰어",
  //   path: "zabbix-dashboard",
  // },
];
