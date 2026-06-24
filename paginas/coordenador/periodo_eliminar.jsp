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

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("periodos.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int periodoId = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM periodos_inscricao pi " +
        "INNER JOIN disciplinas d ON d.id = pi.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE pi.id = ? " +
        "AND u.id = ? " +
        "AND u.perfil = 'COORDENADOR'"
    );

    ps.setInt(1, periodoId);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    int permitido = 0;

    if (rs.next()) {
        permitido = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (permitido == 0) {
        response.sendRedirect("periodos.jsp?erro=periodo_nao_permitido");
        return;
    }

    ps = con.prepareStatement(
        "UPDATE periodos_inscricao " +
        "SET ativo = 0 " +
        "WHERE id = ?"
    );

    ps.setInt(1, periodoId);
    ps.executeUpdate();

    response.sendRedirect("periodos.jsp?sucesso=periodo_inativado");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao inativar período</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='periodos.jsp'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>