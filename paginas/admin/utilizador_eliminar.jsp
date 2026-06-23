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

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("utilizadores.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);
int adminLogadoId = Integer.parseInt(userIdObj.toString());

if (id == adminLogadoId) {
    response.sendRedirect("utilizadores.jsp?erro=nao_podes_eliminar_a_tua_conta");
    return;
}

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "UPDATE utilizadores " +
        "SET ativo = 0 " +
        "WHERE id = ?"
    );

    ps.setInt(1, id);
    ps.executeUpdate();

    response.sendRedirect("utilizadores.jsp?sucesso=utilizador_inativado");
    return;

} catch (Exception e) {
    out.print("Erro ao eliminar/inativar utilizador: " + e.getMessage());

} finally {
    dbClose(null, ps, con);
}
%>