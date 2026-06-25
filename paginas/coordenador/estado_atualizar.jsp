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

String idParam = request.getParameter("id");
String estado = request.getParameter("estado");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/paginas/coordenador/estados.jsp?erro=id_invalido");
    return;
}

if (estado == null || estado.trim().isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/paginas/coordenador/estados.jsp?erro=estado_obrigatorio");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int inscricaoId = Integer.parseInt(idParam);

estado = estado.trim().toUpperCase();

if (
    !"ATIVA".equals(estado) &&
    !"ALTERADA".equals(estado) &&
    !"CANCELADA".equals(estado)
) {
    response.sendRedirect(request.getContextPath() + "/paginas/coordenador/estados.jsp?erro=estado_invalido");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    /*
        Verificar se esta inscrição pertence a uma disciplina
        do coordenador autenticado.
    */
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
        response.sendRedirect(request.getContextPath() + "/paginas/coordenador/estados.jsp?erro=inscricao_nao_permitida");
        return;
    }

    /*
        Atualizar apenas o estado.
    */
    ps = con.prepareStatement(
        "UPDATE inscricoes " +
        "SET estado = ? " +
        "WHERE id = ?"
    );

    ps.setString(1, estado);
    ps.setInt(2, inscricaoId);

    ps.executeUpdate();

    /*
        Depois de atualizar, volta para a página da imagem:
        Consultar Estado.
    */
    response.sendRedirect(request.getContextPath() + "/paginas/coordenador/estados.jsp?sucesso=estado_atualizado");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao atualizar estado</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='" + request.getContextPath() + "/paginas/coordenador/estados.jsp'>Voltar para Consultar Estado</a>");

} finally {
    dbClose(rs, ps, con);
}
%>