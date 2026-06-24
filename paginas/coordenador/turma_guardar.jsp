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

String disciplinaParam = request.getParameter("disciplina_id");
String nome = request.getParameter("nome");
String tipo = request.getParameter("tipo");
String capacidadeMinParam = request.getParameter("capacidade_minima");
String capacidadeMaxParam = request.getParameter("capacidade_maxima");
String ativoParam = request.getParameter("ativo");
String diaSemana = request.getParameter("dia_semana");
String horaInicio = request.getParameter("hora_inicio");
String horaFim = request.getParameter("hora_fim");
String sala = request.getParameter("sala");

if (
    disciplinaParam == null || disciplinaParam.trim().isEmpty() ||
    nome == null || nome.trim().isEmpty() ||
    tipo == null || tipo.trim().isEmpty() ||
    capacidadeMinParam == null || capacidadeMinParam.trim().isEmpty() ||
    capacidadeMaxParam == null || capacidadeMaxParam.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty() ||
    diaSemana == null || diaSemana.trim().isEmpty() ||
    horaInicio == null || horaInicio.trim().isEmpty() ||
    horaFim == null || horaFim.trim().isEmpty() ||
    sala == null || sala.trim().isEmpty()
) {
    response.sendRedirect("turma_criar.jsp?erro=campos_obrigatorios");
    return;
}

int disciplinaId = Integer.parseInt(disciplinaParam);
int capacidadeMinima = Integer.parseInt(capacidadeMinParam);
int capacidadeMaxima = Integer.parseInt(capacidadeMaxParam);
int ativo = Integer.parseInt(ativoParam);

if (capacidadeMaxima < capacidadeMinima) {
    response.sendRedirect("turma_criar.jsp?erro=capacidade_invalida");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

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

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM disciplinas " +
        "WHERE id = ? AND coordenador_id = ? AND ativo = 1"
    );

    ps.setInt(1, disciplinaId);
    ps.setInt(2, coordenadorId);
    rs = dbQuery(con, ps);

    int disciplinaValida = 0;

    if (rs.next()) {
        disciplinaValida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (disciplinaValida == 0) {
        con.rollback();
        response.sendRedirect("turma_criar.jsp?erro=disciplina_nao_permitida");
        return;
    }

    ps = con.prepareStatement(
        "INSERT INTO turmas " +
        "(disciplina_id, nome, tipo, capacidade_minima, capacidade_maxima, ativo) " +
        "VALUES (?, ?, ?, ?, ?, ?)",
        Statement.RETURN_GENERATED_KEYS
    );

    ps.setInt(1, disciplinaId);
    ps.setString(2, nome.trim());
    ps.setString(3, tipo.trim());
    ps.setInt(4, capacidadeMinima);
    ps.setInt(5, capacidadeMaxima);
    ps.setInt(6, ativo);

    ps.executeUpdate();

    rs = ps.getGeneratedKeys();

    int turmaId = 0;

    if (rs.next()) {
        turmaId = rs.getInt(1);
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "INSERT INTO horarios " +
        "(turma_id, dia_semana, hora_inicio, hora_fim, sala) " +
        "VALUES (?, ?, ?, ?, ?)"
    );

    ps.setInt(1, turmaId);
    ps.setString(2, diaSemana.trim());
    ps.setString(3, horaInicio.trim() + ":00");
    ps.setString(4, horaFim.trim() + ":00");
    ps.setString(5, sala.trim());

    ps.executeUpdate();

    con.commit();

    response.sendRedirect("turmas.jsp?sucesso=turma_criada");
    return;

} catch (Exception e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    out.print("Erro ao guardar turma: " + e.getMessage());

} finally {

    if (con != null) {
        try { con.setAutoCommit(true); } catch (Exception ignored) {}
    }

    dbClose(rs, ps, con);
}
%>