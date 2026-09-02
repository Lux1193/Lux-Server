<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;");
    }
    private static final String[] LOCATIONS = {
        "앞베란다A", "앞베란다B", "뒷베란다", "거실서랍", "주방서랍"
    };
    private boolean isValidLocation(String loc) {
        for (String l : LOCATIONS) if (l.equals(loc)) return true;
        return false;
    }
    private static final String GATE_PASSWORD = "3017";
    private static final String GATE_CSS =
        ":root{--bg:#12161b;--bg-elev:#171c22;--panel:#1a2028;--border:#2b3440;--border-strong:#3a4552;" +
        "--amber:#f2a93b;--red:#ff5c5c;--text:#eef1f4;--text-dim:#8a94a1;--text-faint:#5b6472;" +
        "--mono:'IBM Plex Mono',ui-monospace,monospace;--sans:'IBM Plex Sans',-apple-system,sans-serif;}" +
        "*{box-sizing:border-box;margin:0;padding:0;}" +
        "html,body{background:var(--bg);color:var(--text);font-family:var(--sans);min-height:100vh;" +
        "display:flex;align-items:center;justify-content:center;padding:24px;}" +
        ".gate-panel{width:100%;max-width:360px;background:var(--panel);border:1px solid var(--border);" +
        "border-radius:8px;padding:32px 28px;position:relative;}" +
        ".gate-panel::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:8px 8px 0 0;" +
        "background:linear-gradient(90deg,var(--amber),transparent 60%);}" +
        ".gate-title{font-family:var(--mono);font-size:18px;font-weight:700;margin-bottom:6px;}" +
        ".gate-sub{font-family:var(--mono);font-size:12px;color:var(--text-dim);letter-spacing:.04em;margin-bottom:22px;}" +
        ".gate-panel input[type=password]{width:100%;background:var(--bg);border:1px solid var(--border);" +
        "border-radius:5px;padding:14px 16px;color:var(--text);font-size:16px;outline:none;margin-bottom:14px;" +
        "letter-spacing:.2em;text-align:center;}" +
        ".gate-panel input[type=password]:focus{border-color:var(--amber);}" +
        ".gate-btn{width:100%;padding:14px;min-height:48px;background:var(--amber);color:var(--bg);border:none;" +
        "border-radius:5px;font-family:var(--mono);font-size:14px;font-weight:700;letter-spacing:.08em;cursor:pointer;}" +
        ".gate-error{font-family:var(--mono);font-size:12px;color:var(--red);margin-bottom:14px;}" +
        ".gate-back{display:inline-block;margin-top:18px;color:var(--text-faint);font-family:var(--mono);" +
        "font-size:11px;letter-spacing:.06em;text-decoration:none;}" +
        ".gate-back:hover{color:var(--amber);}";
%>
<%
    request.setCharacterEncoding("UTF-8");

    HttpSession sess = request.getSession(true);
    boolean loginError = false;

    if ("POST".equalsIgnoreCase(request.getMethod()) && "login".equals(request.getParameter("gate_action"))) {
        String pw = request.getParameter("gate_password");
        if (GATE_PASSWORD.equals(pw)) {
            sess.setAttribute("inv_authed", Boolean.TRUE);
            response.sendRedirect(request.getContextPath() + "/");
            return;
        } else {
            loginError = true;
        }
    }

    Boolean authed = (Boolean) sess.getAttribute("inv_authed");
    if (authed == null || !authed) {
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>재고관리 - 비밀번호 확인</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style><%= GATE_CSS %></style>
</head>
<body>
  <div class="gate-panel">
    <div class="gate-title">재고관리 / Inventory</div>
    <div class="gate-sub">비밀번호를 입력해야 접속할 수 있습니다.</div>
    <form method="post" action="<%= request.getContextPath() %>/">
      <input type="hidden" name="gate_action" value="login">
<%      if (loginError) { %>
      <div class="gate-error">비밀번호가 올바르지 않습니다.</div>
<%      } %>
      <input type="password" name="gate_password" inputmode="numeric" placeholder="PASSWORD" autofocus required>
      <button type="submit" class="gate-btn">확인</button>
    </form>
    <a href="../index.html" class="gate-back">&#8592; BACK</a>
  </div>
</body>
</html>
<%
        return;
    }

    String dbUrl = "jdbc:mariadb://mariadb:3306/myappdb";
    String dbUser = "appuser";
    String dbPass = "apppassword123!";

    Class.forName("org.mariadb.jdbc.Driver");

    try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

        try (Statement st = conn.createStatement()) {
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS inventory_items (" +
                "  id INT AUTO_INCREMENT PRIMARY KEY," +
                "  item_name VARCHAR(100) NOT NULL," +
                "  location VARCHAR(20) NOT NULL," +
                "  quantity INT NOT NULL DEFAULT 0," +
                "  note VARCHAR(255)," +
                "  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                ") CHARACTER SET utf8mb4"
            );
        }

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String action = request.getParameter("action");

            if ("add".equals(action)) {
                String name = request.getParameter("item_name");
                String loc = request.getParameter("location");
                String qtyStr = request.getParameter("quantity");
                String note = request.getParameter("note");
                if (name != null && loc != null && qtyStr != null
                        && name.trim().length() > 0 && isValidLocation(loc)) {
                    int qty;
                    try { qty = Integer.parseInt(qtyStr.trim()); } catch (Exception e) { qty = 0; }
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO inventory_items (item_name, location, quantity, note) VALUES (?, ?, ?, ?)")) {
                        ps.setString(1, name.trim());
                        ps.setString(2, loc);
                        ps.setInt(3, qty);
                        ps.setString(4, (note == null || note.trim().length() == 0) ? null : note.trim());
                        ps.executeUpdate();
                    }
                }
            } else if ("update".equals(action)) {
                String idStr = request.getParameter("id");
                String name = request.getParameter("item_name");
                String loc = request.getParameter("location");
                String qtyStr = request.getParameter("quantity");
                String note = request.getParameter("note");
                if (idStr != null && name != null && loc != null && qtyStr != null
                        && name.trim().length() > 0 && isValidLocation(loc)) {
                    int id, qty;
                    try { id = Integer.parseInt(idStr.trim()); } catch (Exception e) { id = -1; }
                    try { qty = Integer.parseInt(qtyStr.trim()); } catch (Exception e) { qty = 0; }
                    if (id > 0) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "UPDATE inventory_items SET item_name=?, location=?, quantity=?, note=? WHERE id=?")) {
                            ps.setString(1, name.trim());
                            ps.setString(2, loc);
                            ps.setInt(3, qty);
                            ps.setString(4, (note == null || note.trim().length() == 0) ? null : note.trim());
                            ps.setInt(5, id);
                            ps.executeUpdate();
                        }
                    }
                }
            } else if ("delete".equals(action)) {
                String idStr = request.getParameter("id");
                if (idStr != null) {
                    int id;
                    try { id = Integer.parseInt(idStr.trim()); } catch (Exception e) { id = -1; }
                    if (id > 0) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "DELETE FROM inventory_items WHERE id=?")) {
                            ps.setInt(1, id);
                            ps.executeUpdate();
                        }
                    }
                }
            }
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        String q = request.getParameter("q");
        String locFilter = request.getParameter("loc");
        if (q == null) q = "";
        if (locFilter == null) locFilter = "";

        String editIdStr = request.getParameter("edit");
        Integer editId = null;
        String editName = "", editNote = "";
        String editLoc = "";
        int editQty = 0;
        if (editIdStr != null) {
            try {
                int eid = Integer.parseInt(editIdStr.trim());
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT item_name, location, quantity, note FROM inventory_items WHERE id=?")) {
                    ps.setInt(1, eid);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            editId = eid;
                            editName = rs.getString("item_name");
                            editLoc = rs.getString("location");
                            editQty = rs.getInt("quantity");
                            editNote = rs.getString("note");
                            if (editNote == null) editNote = "";
                        }
                    }
                }
            } catch (Exception e) { /* ignore invalid edit id */ }
        }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>POSCO KRY TOOLBOX - 재고관리</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #12161b;
    --bg-elev: #171c22;
    --panel: #1a2028;
    --border: #2b3440;
    --border-strong: #3a4552;
    --amber: #f2a93b;
    --red: #ff5c5c;
    --text: #eef1f4;
    --text-dim: #8a94a1;
    --text-faint: #5b6472;
    --mono: 'IBM Plex Mono', ui-monospace, monospace;
    --sans: 'IBM Plex Sans', -apple-system, sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  html, body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    min-height: 100vh;
    background-image:
      linear-gradient(var(--bg-elev) 1px, transparent 1px),
      linear-gradient(90deg, var(--bg-elev) 1px, transparent 1px);
    background-size: 40px 40px;
    background-position: center top;
  }

  .wrap {
    max-width: 820px;
    margin: 0 auto;
    padding: 24px 16px 60px;
  }

  .tool-header {
    border: 1px solid var(--border);
    border-radius: 6px;
    background: linear-gradient(180deg, var(--bg-elev), var(--bg));
    padding: 20px 24px;
    margin-bottom: 20px;
    position: relative;
  }

  .tool-header::before {
    content: "";
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 3px;
    background: linear-gradient(90deg, var(--amber), transparent 60%);
  }

  .back-link {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: var(--amber);
    text-decoration: none;
    font-family: var(--mono);
    font-size: 12px;
    letter-spacing: .08em;
    font-weight: 500;
    margin-bottom: 8px;
  }
  .back-link:hover { opacity: 0.8; }

  .tool-title {
    font-family: var(--mono);
    font-size: 22px;
    font-weight: 700;
    letter-spacing: .02em;
  }

  .tool-panel {
    background: var(--panel);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 20px;
    position: relative;
    margin-bottom: 20px;
  }

  .rivet {
    position: absolute;
    width: 5px; height: 5px;
    border-radius: 50%;
    background: var(--border-strong);
  }
  .rivet.tl { top: 8px; left: 8px; }
  .rivet.tr { top: 8px; right: 8px; }
  .rivet.bl { bottom: 8px; left: 8px; }
  .rivet.br { bottom: 8px; right: 8px; }

  .form-row {
    display: grid;
    grid-template-columns: 2fr 1.3fr 0.8fr;
    gap: 12px;
    margin-bottom: 12px;
  }

  .form-group label {
    display: block;
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text-dim);
    letter-spacing: .08em;
    text-transform: uppercase;
    margin-bottom: 8px;
  }

  input[type="text"], input[type="number"], select, textarea {
    width: 100%;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 13px 14px;
    color: var(--text);
    font-family: var(--sans);
    font-size: 16px;
    outline: none;
    transition: border-color 0.15s ease;
  }

  input:focus, select:focus, textarea:focus {
    border-color: var(--amber);
  }

  .form-actions {
    display: flex;
    gap: 10px;
    margin-top: 4px;
  }

  .btn-submit {
    flex: 1;
    padding: 14px;
    min-height: 48px;
    background: var(--amber);
    color: var(--bg);
    border: none;
    border-radius: 4px;
    font-family: var(--mono);
    font-size: 14px;
    font-weight: 700;
    letter-spacing: .08em;
    cursor: pointer;
    transition: background 0.15s ease, transform 0.15s ease;
  }
  .btn-submit:hover { background: #e0982e; transform: translateY(-1px); }

  .btn-cancel {
    padding: 14px 20px;
    min-height: 48px;
    background: transparent;
    color: var(--text-dim);
    border: 1px solid var(--border);
    border-radius: 4px;
    font-family: var(--mono);
    font-size: 14px;
    letter-spacing: .08em;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
  }
  .btn-cancel:hover { border-color: var(--border-strong); color: var(--text); }

  .search-panel {
    display: flex;
    gap: 10px;
    margin-bottom: 18px;
    flex-wrap: wrap;
  }
  .search-panel input[type="text"] { flex: 2; min-width: 140px; }
  .search-panel select { flex: 1; min-width: 120px; }
  .search-panel button {
    padding: 0 22px;
    min-height: 48px;
    background: var(--panel);
    color: var(--amber);
    border: 1px solid var(--border-strong);
    border-radius: 4px;
    font-family: var(--mono);
    font-size: 13px;
    letter-spacing: .06em;
    cursor: pointer;
  }
  .search-panel button:hover { border-color: var(--amber); }

  .section-label {
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 0 0 12px;
    font-family: var(--mono);
    font-size: 12px;
    letter-spacing: .14em;
    text-transform: uppercase;
    color: var(--text-faint);
  }
  .section-label::after {
    content: "";
    flex: 1;
    height: 1px;
    background: var(--border);
  }

  table { width: 100%; border-collapse: collapse; font-size: 13.5px; }
  thead th {
    text-align: left;
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: .06em;
    text-transform: uppercase;
    color: var(--text-faint);
    padding: 0 12px 10px;
    border-bottom: 1px solid var(--border);
    white-space: nowrap;
  }
  tbody td {
    padding: 12px;
    border-bottom: 1px solid var(--border);
    vertical-align: top;
  }
  tbody tr:hover { background: rgba(255,255,255,0.02); }

  .item-name { font-weight: 600; color: var(--text); }
  .loc-badge {
    display: inline-block;
    font-family: var(--mono);
    font-size: 11px;
    color: var(--amber);
    border: 1px solid var(--border-strong);
    border-radius: 3px;
    padding: 3px 8px;
    white-space: nowrap;
  }
  .qty { font-family: var(--mono); font-weight: 700; }
  .note-cell { color: var(--text-dim); max-width: 220px; word-break: break-word; }
  .updated-cell { font-family: var(--mono); font-size: 11px; color: var(--text-faint); white-space: nowrap; }

  .row-actions { display: flex; gap: 8px; white-space: nowrap; }
  .row-actions a, .row-actions button {
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: .04em;
    background: none;
    border: 1px solid var(--border-strong);
    border-radius: 3px;
    padding: 5px 9px;
    cursor: pointer;
    text-decoration: none;
  }
  .row-actions a { color: var(--text-dim); }
  .row-actions a:hover { color: var(--amber); border-color: var(--amber); }
  .row-actions button { color: var(--red); }
  .row-actions button:hover { border-color: var(--red); }

  .empty {
    border: 1px dashed var(--border);
    border-radius: 5px;
    padding: 40px 20px;
    text-align: center;
    color: var(--text-faint);
    font-family: var(--mono);
    font-size: 13px;
  }

  /* ── Mobile: table becomes a stack of cards ────────────── */
  @media (max-width: 640px) {
    .wrap { padding: 16px 12px 40px; }
    .tool-header { padding: 16px; }
    .tool-panel { padding: 16px; }
    .tool-title { font-size: 19px; }
    .form-row { grid-template-columns: 1fr; gap: 12px; }
    .search-panel { flex-direction: column; }
    .search-panel input[type="text"], .search-panel select, .search-panel button { width: 100%; }
    .form-actions { flex-direction: column; }
    .btn-cancel { justify-content: center; }

    .table-wrap { overflow-x: visible; }
    table, thead, tbody, th, td, tr { display: block; }
    thead { display: none; }
    tbody tr {
      border: 1px solid var(--border);
      border-radius: 6px;
      margin-bottom: 12px;
      padding: 4px 14px;
      background: var(--panel);
    }
    tbody td {
      border: none;
      padding: 10px 0;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
    }
    tbody td:last-child { border-bottom: none; }
    tbody td::before {
      content: attr(data-label);
      font-family: var(--mono);
      font-size: 10.5px;
      color: var(--text-faint);
      text-transform: uppercase;
      letter-spacing: .04em;
      flex-shrink: 0;
      padding-top: 2px;
    }
    tbody td.actions-cell::before { content: none; }
    tbody td.actions-cell { justify-content: flex-end; }
    .row-actions a, .row-actions button {
      padding: 10px 16px;
      font-size: 12px;
      min-height: 40px;
    }
  }
</style>
</head>
<body>

<div class="wrap">

  <header class="tool-header">
    <a href="../index.html" class="back-link">&#8592; BACK TO POSCO KRY TOOLBOX</a>
    <h1 class="tool-title">재고관리 / Inventory</h1>
  </header>

  <main class="tool-panel">
    <span class="rivet tl"></span><span class="rivet tr"></span>
    <span class="rivet bl"></span><span class="rivet br"></span>

    <div class="section-label"><%= editId != null ? "물건 수정" : "물건 등록" %></div>

    <form method="post" action="<%= request.getContextPath() %>/">
      <input type="hidden" name="action" value="<%= editId != null ? "update" : "add" %>">
      <% if (editId != null) { %>
        <input type="hidden" name="id" value="<%= editId %>">
      <% } %>
      <div class="form-row">
        <div class="form-group">
          <label>물건명</label>
          <input type="text" name="item_name" placeholder="예: 드라이버 세트" maxlength="100" value="<%= esc(editName) %>" required>
        </div>
        <div class="form-group">
          <label>보관위치</label>
          <select name="location" required>
            <option value="" disabled <%= editId == null ? "selected" : "" %>>선택하세요</option>
<%
        for (String loc : LOCATIONS) {
            String sel = loc.equals(editLoc) ? "selected" : "";
%>
            <option value="<%= loc %>" <%= sel %>><%= loc %></option>
<%
        }
%>
          </select>
        </div>
        <div class="form-group">
          <label>수량</label>
          <input type="number" name="quantity" min="0" step="1" value="<%= editId != null ? editQty : 1 %>" required>
        </div>
      </div>
      <div class="form-group" style="margin-bottom:14px;">
        <label>비고 (선택)</label>
        <input type="text" name="note" placeholder="예: 파란색 케이스, 상태 양호" maxlength="255" value="<%= esc(editNote) %>">
      </div>
      <div class="form-actions">
        <button type="submit" class="btn-submit"><%= editId != null ? "수정 완료" : "등록" %></button>
<% if (editId != null) { %>
        <a href="<%= request.getContextPath() %>/" class="btn-cancel">취소</a>
<% } %>
      </div>
    </form>
  </main>

  <div class="section-label">검색</div>
  <form method="get" action="<%= request.getContextPath() %>/" class="search-panel">
    <input type="text" name="q" placeholder="물건명으로 검색" value="<%= esc(q) %>">
    <select name="loc">
      <option value="">전체 위치</option>
<%
        for (String loc : LOCATIONS) {
            String sel = loc.equals(locFilter) ? "selected" : "";
%>
      <option value="<%= loc %>" <%= sel %>><%= loc %></option>
<%
        }
%>
    </select>
    <button type="submit">검색</button>
  </form>

  <div class="section-label">보관 물품 목록</div>

  <div class="table-wrap">
<%
        StringBuilder sql = new StringBuilder(
            "SELECT id, item_name, location, quantity, note, updated_at FROM inventory_items WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (q.trim().length() > 0) {
            sql.append(" AND item_name LIKE ?");
            params.add("%" + q.trim() + "%");
        }
        if (locFilter.trim().length() > 0 && isValidLocation(locFilter)) {
            sql.append(" AND location = ?");
            params.add(locFilter);
        }
        sql.append(" ORDER BY location ASC, item_name ASC");

        boolean any = false;
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
%>
    <table>
      <thead>
        <tr>
          <th>물건명</th>
          <th>위치</th>
          <th>수량</th>
          <th>비고</th>
          <th>최근수정</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
<%
                while (rs.next()) {
                    any = true;
                    int id = rs.getInt("id");
%>
        <tr>
          <td data-label="물건명" class="item-name"><%= esc(rs.getString("item_name")) %></td>
          <td data-label="위치"><span class="loc-badge"><%= esc(rs.getString("location")) %></span></td>
          <td data-label="수량" class="qty"><%= rs.getInt("quantity") %></td>
          <td data-label="비고" class="note-cell"><%= esc(rs.getString("note")) %></td>
          <td data-label="최근수정" class="updated-cell"><%= rs.getTimestamp("updated_at") %></td>
          <td class="actions-cell">
            <div class="row-actions">
              <a href="<%= request.getContextPath() %>/index.html?edit=<%= id %>">수정</a>
              <form method="post" action="<%= request.getContextPath() %>/" style="display:inline"
                    onsubmit="return confirm('정말 삭제하시겠습니까?');">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<%= id %>">
                <button type="submit">삭제</button>
              </form>
            </div>
          </td>
        </tr>
<%
                }
%>
      </tbody>
    </table>
<%
            }
        }
        if (!any) {
%>
    <div class="empty">해당하는 물건이 없습니다.</div>
<%
        }
%>
  </div>

</div>

</body>
</html>
<%
    }
%>
