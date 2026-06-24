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

String disciplinaParam = request.getParameter("disciplina_id");
String dataInicioParam = request.getParameter("data_inicio");
String dataFimParam = request.getParameter("data_fim");
String ativoParam = request.getParameter("ativo");

if (
    disciplinaParam == null || disciplinaParam.trim().isEmpty() ||
    dataInicioParam == null || dataInicioParam.trim().isEmpty() ||
    dataFimParam == null || dataFimParam.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty()
) {
    response.sendRedirect("periodo_criar.jsp?erro=campos_obrigatorios");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int disciplinaId = Integer.parseInt(disciplinaParam);
int ativo = Integer.parseInt(ativoParam);

String dataInicio = normalizarDataHora(dataInicioParam);
String dataFim = normalizarDataHora(dataFimParam);

if (dataFim.compareTo(dataInicio) <= 0) {
    response.sendRedirect("periodo_criar.jsp?erro=data_invalida");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT c.id AS coordenador_id " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    int coordenadorId = 0;

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (coordenadorId == 0) {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM disciplinas " +
        "WHERE id = ? AND coordenador_id = ? AND ativo = 1"
    );

    ps.setInt(1, disciplinaId);
    ps.setInt(2, coordenadorId);
    rs = dbQuery(con, ps);

    int disciplinaPermitida = 0;

    if (rs.next()) {
        disciplinaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (disciplinaPermitida == 0) {
        response.sendRedirect("periodo_criar.jsp?erro=disciplina_nao_permitida");
        return;
    }

    ps = con.prepareStatement(
        "INSERT INTO periodos_inscricao " +
        "(disciplina_id, data_inicio, data_fim, ativo) " +
        "VALUES (?, ?, ?, ?)"
    );

    ps.setInt(1, disciplinaId);
    ps.setString(2, dataInicio);
    ps.setString(3, dataFim);
    ps.setInt(4, ativo);

    ps.executeUpdate();

    response.sendRedirect("periodos.jsp?sucesso=periodo_criado");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    response.sendRedirect("periodo_criar.jsp?erro=disciplina_ja_tem_periodo");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao guardar período</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='periodo_criar.jsp'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>