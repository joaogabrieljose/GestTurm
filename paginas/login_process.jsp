<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../database/basedados.h" %>

<%
request.setCharacterEncoding("UTF-8");

String email = request.getParameter("email");
String password = request.getParameter("password");

if (
    email == null ||
    password == null ||
    email.trim().isEmpty() ||
    password.trim().isEmpty()
) {
    response.sendRedirect(
        request.getContextPath() +
        "/paginas/index.jsp?login=campos_obrigatorios"
    );
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT id, nome, email, perfil, ativo " +
        "FROM utilizadores " +
        "WHERE email = ? " +
        "AND password = ? " +
        "LIMIT 1"
    );

    ps.setString(1, email.trim());
    ps.setString(2, password);

    rs = dbQuery(con, ps);

    if (!rs.next()) {
        response.sendRedirect(
            request.getContextPath() +
            "/paginas/index.jsp?login=credenciais_invalidas"
        );
        return;
    }

    boolean ativo = rs.getBoolean("ativo");

    if (!ativo) {
        response.sendRedirect(
            request.getContextPath() +
            "/paginas/index.jsp?login=utilizador_inativo"
        );
        return;
    }

    int userId = rs.getInt("id");
    String nome = rs.getString("nome");
    String perfil = rs.getString("perfil");
    String emailUtilizador = rs.getString("email");

    /*
      Guarda os dados do utilizador na sessão.
    */
    session.setAttribute("userId", userId);
    session.setAttribute("username", nome);
    session.setAttribute("email", emailUtilizador);
    session.setAttribute("perfil", perfil);

    /*
      Redireciona para o dashboard correspondente ao perfil.
    */
    if ("ALUNO".equalsIgnoreCase(perfil)) {
    response.sendRedirect(
        request.getContextPath() + "/paginas/alunos/aluno.jsp"
    );
    return;
    }   

    if ("COORDENADOR".equalsIgnoreCase(perfil)) {
        response.sendRedirect(
            request.getContextPath() +
            "/paginas/coordenador/coordenador.jsp"
        );
        return;
    }

    if ("ADMINISTRADOR".equalsIgnoreCase(perfil)) {
        response.sendRedirect(
            request.getContextPath() +
            "/paginas/admin/admin.jsp"
        );
        return;
    }

    session.invalidate();

    response.sendRedirect(
        request.getContextPath() +
        "/paginas/index.jsp?login=perfil_invalido"
    );

} catch (Exception e) {
    response.sendRedirect(
        request.getContextPath() +
        "/paginas/index.jsp?login=erro"
    );

} finally {
    dbClose(rs, ps, con);
}
%>