<%!

private static final String DB_HOST = "127.0.0.1";
private static final String DB_PORT = "3308";
private static final String DB_NAME = "gesturma_db";
private static final String DB_USER = "root";
private static final String DB_PASS = "";

private static final String DB_URL =
  "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME +
  "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";

public java.sql.Connection dbConnect() throws java.sql.SQLException {
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
    } catch (ClassNotFoundException e) {
        throw new java.sql.SQLException("Driver MySQL não encontrado (mysql-connector-j.jar em Tomcat/lib).", e);
    }
    return java.sql.DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
}

public void dbClose(java.sql.ResultSet rs, java.sql.PreparedStatement ps, java.sql.Connection con) {
    try { if (rs != null) rs.close(); } catch (Exception ignored) {}
    try { if (ps != null) ps.close(); } catch (Exception ignored) {}
    try { if (con != null) con.close(); } catch (Exception ignored) {}
}

public java.sql.ResultSet dbQuery(java.sql.Connection con, java.sql.PreparedStatement ps) throws java.sql.SQLException {
    return ps.executeQuery();
}

public int dbUpdate(java.sql.Connection con, java.sql.PreparedStatement ps) throws java.sql.SQLException {
    return ps.executeUpdate();
}

%>