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
    response.sendRedirect("inscricoes.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int inscricaoId = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE i.id = ? " +
        "AND u.id = ? " +
        "AND u.perfil = 'COORDENADOR'"
    );

    ps.setInt(1, inscricaoId);
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
        response.sendRedirect("inscricoes.jsp?erro=inscricao_nao_permitida");
        return;
    }

    ps = con.prepareStatement(
        "UPDATE inscricoes " +
        "SET estado = 'CANCELADA' " +
        "WHERE id = ?"
    );

    ps.setInt(1, inscricaoId);
    ps.executeUpdate();

    response.sendRedirect("inscricoes.jsp?sucesso=inscricao_cancelada");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao cancelar inscrição</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='inscricoes.jsp'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>