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
<title>방명록 - posco-kry.site</title>
<style>
  body { font-family: -apple-system, sans-serif; max-width: 600px; margin: 40px auto; padding: 0 16px; color: #222; }
  h1 { font-size: 1.4rem; }
  a.back { display: inline-block; margin-bottom: 16px; color: #555; text-decoration: none; }
  form { display: flex; flex-direction: column; gap: 8px; margin-bottom: 28px; }
  input, textarea { padding: 8px; font-size: 1rem; font-family: inherit; border: 1px solid #ccc; border-radius: 4px; }
  button { padding: 10px; font-size: 1rem; cursor: pointer; border: none; border-radius: 4px; background: #333; color: #fff; }
  .entry { border-bottom: 1px solid #eee; padding: 12px 0; }
  .entry .name { font-weight: bold; }
  .entry .date { color: #999; font-size: 0.8rem; margin-left: 6px; }
  .entry .message { margin-top: 4px; white-space: pre-wrap; }
  .empty { color: #999; padding: 20px 0; }
</style>
</head>
<body>
  <a class="back" href="/">&larr; 메인으로</a>
  <h1>방명록</h1>
  <form method="post" action="">
    <input type="text" name="name" placeholder="이름" maxlength="50" required>
    <textarea name="message" placeholder="메시지" maxlength="500" rows="3" required></textarea>
    <button type="submit">남기기</button>
  </form>
  <div class="list">
<%
        boolean any = false;
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT name, message, created_at FROM guestbook ORDER BY id DESC")) {
            while (rs.next()) {
                any = true;
%>
    <div class="entry">
      <span class="name"><%= esc(rs.getString("name")) %></span>
      <span class="date"><%= rs.getTimestamp("created_at") %></span>
      <div class="message"><%= esc(rs.getString("message")) %></div>
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
