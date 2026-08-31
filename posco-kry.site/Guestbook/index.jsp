<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    request.setCharacterEncoding("UTF-8");

    String dbUrl = "jdbc:mariadb://mariadb:3306/myappdb";
    String dbUser = "appuser";
    String dbPass = "apppassword123!";

    Class.forName("org.mariadb.jdbc.Driver");

    try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

        try (Statement st = conn.createStatement()) {
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS guestbook (" +
                "  id INT AUTO_INCREMENT PRIMARY KEY," +
                "  name VARCHAR(50) NOT NULL," +
                "  message VARCHAR(500) NOT NULL," +
                "  created_at DATETIME DEFAULT CURRENT_TIMESTAMP" +
                ") CHARACTER SET utf8mb4"
            );
        }

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String name = request.getParameter("name");
            String message = request.getParameter("message");
            if (name != null && message != null
                    && name.trim().length() > 0 && message.trim().length() > 0) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO guestbook (name, message) VALUES (?, ?)")) {
                    ps.setString(1, name.trim());
                    ps.setString(2, message.trim());
                    ps.executeUpdate();
                }
            }
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>POSCO KRY TOOLBOX - 방명록</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #12161b;
    --bg-elev: #171c22;
    --panel: #1a2028;
    --panel-hover: #1f2630;
    --border: #2b3440;
    --border-strong: #3a4552;
    --amber: #f2a93b;
    --amber-dim: #8a6423;
    --green: #3ddc97;
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
    max-width: 680px;
    margin: 0 auto;
    padding: 40px 24px 80px;
  }

  /* ── Header / Navigation ───────────────────── */
  .tool-header {
    border: 1px solid var(--border);
    border-radius: 6px;
    background: linear-gradient(180deg, var(--bg-elev), var(--bg));
    padding: 24px 32px;
    margin-bottom: 24px;
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
    transition: opacity 0.15s ease;
  }
  .back-link:hover { opacity: 0.8; }

  .tool-title {
    font-family: var(--mono);
    font-size: 24px;
    font-weight: 700;
    color: var(--text);
    letter-spacing: .02em;
  }

  /* ── Main Panel ───────────────────────────── */
  .tool-panel {
    background: var(--panel);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 32px;
    position: relative;
    margin-bottom: 24px;
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

  .form-group { margin-bottom: 20px; }
  .form-group:last-of-type { margin-bottom: 24px; }

  label {
    display: block;
    font-family: var(--mono);
    font-size: 12px;
    color: var(--text-dim);
    letter-spacing: .08em;
    text-transform: uppercase;
    margin-bottom: 10px;
  }

  input[type="text"], textarea {
    width: 100%;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 14px 16px;
    color: var(--text);
    font-family: var(--sans);
    font-size: 15px;
    outline: none;
    transition: border-color 0.15s ease;
    resize: vertical;
  }

  input[type="text"]:focus, textarea:focus {
    border-color: var(--amber);
  }

  .btn-submit {
    width: 100%;
    padding: 16px;
    background: var(--amber);
    color: var(--bg);
    border: none;
    border-radius: 4px;
    font-family: var(--mono);
    font-size: 15px;
    font-weight: 700;
    letter-spacing: .08em;
    cursor: pointer;
    transition: background 0.15s ease, transform 0.15s ease;
  }

  .btn-submit:hover {
    background: #e0982e;
    transform: translateY(-1px);
  }

  /* ── Section label ──────────────────────────── */
  .section-label {
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 0 0 14px;
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

  /* ── Entries ─────────────────────────────────── */
  .entry {
    background: var(--panel);
    border: 1px solid var(--border);
    border-radius: 5px;
    padding: 16px 18px;
    margin-bottom: 12px;
  }

  .entry-head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 8px;
    flex-wrap: wrap;
  }

  .entry-name {
    font-family: var(--mono);
    font-size: 14px;
    font-weight: 700;
    color: var(--amber);
    letter-spacing: .01em;
  }

  .entry-date {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text-faint);
    letter-spacing: .04em;
    white-space: nowrap;
  }

  .entry-message {
    font-size: 14px;
    line-height: 1.6;
    color: var(--text);
    white-space: pre-wrap;
    word-break: break-word;
  }

  .empty {
    border: 1px dashed var(--border);
    border-radius: 5px;
    padding: 40px 20px;
    text-align: center;
    color: var(--text-faint);
    font-family: var(--mono);
    font-size: 13px;
  }

  @media (max-width: 520px) {
    .wrap { padding: 24px 16px 40px; }
    .tool-header { padding: 20px; }
    .tool-panel { padding: 20px; }
    .tool-title { font-size: 20px; }
  }
</style>
</head>
<body>

<div class="wrap">

  <header class="tool-header">
    <a href="../index.html" class="back-link">&#8592; BACK TO TOOLBOX</a>
    <h1 class="tool-title">GUESTBOOK / 방명록</h1>
  </header>

  <main class="tool-panel">
    <span class="rivet tl"></span><span class="rivet tr"></span>
    <span class="rivet bl"></span><span class="rivet br"></span>

    <form method="post" action="">
      <div class="form-group">
        <label for="name">Name / 이름</label>
        <input type="text" id="name" name="name" placeholder="이름을 입력하세요" maxlength="50" required>
      </div>
      <div class="form-group">
        <label for="message">Message / 메시지</label>
        <textarea id="message" name="message" placeholder="남길 메시지를 입력하세요" maxlength="500" rows="4" required></textarea>
      </div>
      <button type="submit" class="btn-submit">SUBMIT / 남기기</button>
    </form>
  </main>

  <div class="section-label">Recent Entries</div>

<%
        boolean any = false;
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT name, message, created_at FROM guestbook ORDER BY id DESC")) {
            while (rs.next()) {
                any = true;
%>
  <div class="entry">
    <div class="entry-head">
      <span class="entry-name"><%= esc(rs.getString("name")) %></span>
      <span class="entry-date"><%= rs.getTimestamp("created_at") %></span>
    </div>
    <div class="entry-message"><%= esc(rs.getString("message")) %></div>
  </div>
<%
            }
        }
        if (!any) {
%>
  <div class="empty">아직 남겨진 글이 없습니다.</div>
<%
        }
%>

</div>

</body>
</html>
<%
    }
%>
