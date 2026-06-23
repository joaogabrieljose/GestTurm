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

request.setCharacterEncoding("UTF-8");

String idParam = request.getParameter("id");
String horarioIdParam = request.getParameter("horario_id");

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
    idParam == null || idParam.trim().isEmpty() ||
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
    response.sendRedirect("turmas.jsp?erro=campos_obrigatorios");
    return;
}

int id = Integer.parseInt(idParam);
int horarioId = 0;

if (horarioIdParam != null && !horarioIdParam.trim().isEmpty()) {
    horarioId = Integer.parseInt(horarioIdParam);
}

int disciplinaId = Integer.parseInt(disciplinaParam);
int capacidadeMinima = Integer.parseInt(capacidadeMinParam);
int capacidadeMaxima = Integer.parseInt(capacidadeMaxParam);
int ativo = Integer.parseInt(ativoParam);

if (capacidadeMaxima < capacidadeMinima) {
    response.sendRedirect("turma_editar.jsp?id=" + id + "&erro=capacidade_invalida");
    return;
}

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    ps = con.prepareStatement(
        "UPDATE turmas " +
        "SET disciplina_id = ?, nome = ?, tipo = ?, capacidade_minima = ?, capacidade_maxima = ?, ativo = ? " +
        "WHERE id = ?"
    );

    ps.setInt(1, disciplinaId);
    ps.setString(2, nome.trim());
    ps.setString(3, tipo.trim());
    ps.setInt(4, capacidadeMinima);
    ps.setInt(5, capacidadeMaxima);
    ps.setInt(6, ativo);
    ps.setInt(7, id);

    ps.executeUpdate();

    dbClose(null, ps, null);
    ps = null;

    if (horarioId > 0) {

        ps = con.prepareStatement(
            "UPDATE horarios " +
            "SET dia_semana = ?, hora_inicio = ?, hora_fim = ?, sala = ? " +
            "WHERE id = ? AND turma_id = ?"
        );

        ps.setString(1, diaSemana.trim());
        ps.setString(2, horaInicio.trim() + ":00");
        ps.setString(3, horaFim.trim() + ":00");
        ps.setString(4, sala.trim());
        ps.setInt(5, horarioId);
        ps.setInt(6, id);

        ps.executeUpdate();

    } else {

        ps = con.prepareStatement(
            "INSERT INTO horarios " +
            "(turma_id, dia_semana, hora_inicio, hora_fim, sala) " +
            "VALUES (?, ?, ?, ?, ?)"
        );

        ps.setInt(1, id);
        ps.setString(2, diaSemana.trim());
        ps.setString(3, horaInicio.trim() + ":00");
        ps.setString(4, horaFim.trim() + ":00");
        ps.setString(5, sala.trim());

        ps.executeUpdate();
    }

    con.commit();

    response.sendRedirect("turmas.jsp?sucesso=turma_atualizada");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    response.sendRedirect("turma_editar.jsp?id=" + id + "&erro=turma_duplicada_ou_horario_invalido");
    return;

} catch (Exception e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    out.print("Erro ao atualizar turma: " + e.getMessage());

} finally {

    if (con != null) {
        try { con.setAutoCommit(true); } catch (Exception ignored) {}
    }

    dbClose(null, ps, con);
}
%>