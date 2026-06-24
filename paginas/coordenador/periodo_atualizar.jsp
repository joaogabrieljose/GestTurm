<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%!
public String normalizarDataHora(String valor) {
    if (valor == null) {
        return "";
    }

    valor = valor.trim().replace("T", " ");

    if (valor.length() == 16) {
        return valor + ":00";
    }

    return valor;
}
%>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"COORDENADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

request.setCharacterEncoding("UTF-8");

String idParam = request.getParameter("id");
String dataInicioParam = request.getParameter("data_inicio");
String dataFimParam = request.getParameter("data_fim");
String ativoParam = request.getParameter("ativo");

if (
    idParam == null || idParam.trim().isEmpty() ||
    dataInicioParam == null || dataInicioParam.trim().isEmpty() ||
    dataFimParam == null || dataFimParam.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty()
) {
    response.sendRedirect("periodos.jsp?erro=campos_obrigatorios");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int periodoId = Integer.parseInt(idParam);
int ativo = Integer.parseInt(ativoParam);

String dataInicio = normalizarDataHora(dataInicioParam);
String dataFim = normalizarDataHora(dataFimParam);

if (dataFim.compareTo(dataInicio) <= 0) {
    response.sendRedirect("periodo_editar.jsp?id=" + periodoId + "&erro=data_invalida");
    return;
}

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
        "SET data_inicio = ?, data_fim = ?, ativo = ? " +
        "WHERE id = ?"
    );

    ps.setString(1, dataInicio);
    ps.setString(2, dataFim);
    ps.setInt(3, ativo);
    ps.setInt(4, periodoId);

    ps.executeUpdate();

    response.sendRedirect("periodos.jsp?sucesso=periodo_atualizado");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao atualizar período</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='periodo_editar.jsp?id=" + periodoId + "'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>