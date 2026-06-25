<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"COORDENADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

request.setCharacterEncoding("UTF-8");

int userId = Integer.parseInt(userIdObj.toString());

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String curso = request.getParameter("curso");
String password = request.getParameter("password");

if (
    nome == null || nome.trim().isEmpty() ||
    email == null || email.trim().isEmpty() ||
    curso == null || curso.trim().isEmpty()
) {
    response.sendRedirect("perfil.jsp?erro=campos_obrigatorios");
    return;
}

nome = nome.trim();
email = email.trim();
curso = curso.trim();

if (password != null) {
    password = password.trim();
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    /*
        Verificar se o coordenador existe.
    */
    ps = con.prepareStatement(
        "SELECT c.id AS coordenador_id " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? " +
        "AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    int coordenadorId = 0;

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    /*
        Verificar se o email já pertence a outro utilizador.
    */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM utilizadores " +
        "WHERE email = ? " +
        "AND id <> ?"
    );

    ps.setString(1, email);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    int emailExistente = 0;

    if (rs.next()) {
        emailExistente = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (emailExistente > 0) {
        response.sendRedirect("perfil.jsp?erro=email_existente");
        return;
    }

    /*
        Atualizar dados do utilizador.
        A palavra-passe só é alterada se for preenchida.
    */
    if (password != null && !password.isEmpty()) {
        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ?, password = ? " +
            "WHERE id = ?"
        );

        ps.setString(1, nome);
        ps.setString(2, email);
        ps.setString(3, password);
        ps.setInt(4, userId);

    } else {
        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ? " +
            "WHERE id = ?"
        );

        ps.setString(1, nome);
        ps.setString(2, email);
        ps.setInt(3, userId);
    }

    ps.executeUpdate();

    dbClose(null, ps, null);
    ps = null;

    /*
        Atualizar dados próprios do coordenador.
    */
    ps = con.prepareStatement(
        "UPDATE coordenadores " +
        "SET curso = ? " +
        "WHERE id = ?"
    );

    ps.setString(1, curso);
    ps.setInt(2, coordenadorId);

    ps.executeUpdate();

    response.sendRedirect("perfil.jsp?sucesso=perfil_atualizado");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao atualizar perfil</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='perfil.jsp'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>