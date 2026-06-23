<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("disciplinas.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "UPDATE disciplinas " +
        "SET ativo = 0 " +
        "WHERE id = ?"
    );

    ps.setInt(1, id);
    ps.executeUpdate();

    response.sendRedirect("disciplinas.jsp?sucesso=disciplina_inativada");
    return;

} catch (Exception e) {
    out.print("Erro ao eliminar/inativar disciplina: " + e.getMessage());

} finally {
    dbClose(null, ps, con);
}
%>