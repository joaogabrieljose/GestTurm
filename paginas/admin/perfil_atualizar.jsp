<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfilSessao = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfilSessao == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfilSessao)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

request.setCharacterEncoding("UTF-8");

int userId = Integer.parseInt(userIdObj.toString());

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String password = request.getParameter("password");

if (
    nome == null || nome.trim().isEmpty() ||
    email == null || email.trim().isEmpty()
) {
    response.sendRedirect("perfil.jsp?erro=campos_obrigatorios");
    return;
}

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();

    if (password != null && !password.trim().isEmpty()) {

        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ?, password = ? " +
            "WHERE id = ? AND perfil = 'ADMINISTRADOR'"
        );

        ps.setString(1, nome.trim());
        ps.setString(2, email.trim());
        ps.setString(3, password.trim());
        ps.setInt(4, userId);

    } else {

        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ? " +
            "WHERE id = ? AND perfil = 'ADMINISTRADOR'"
        );

        ps.setString(1, nome.trim());
        ps.setString(2, email.trim());
        ps.setInt(3, userId);
    }

    ps.executeUpdate();

    session.setAttribute("username", nome.trim());
    session.setAttribute("email", email.trim());

    response.sendRedirect("perfil.jsp?sucesso=perfil_atualizado");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    response.sendRedirect("perfil.jsp?erro=email_duplicado");
    return;

} catch (Exception e) {

    out.print("Erro ao atualizar perfil: " + e.getMessage());

} finally {
    dbClose(null, ps, con);
}
%>