<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%!
public String normalizarHora(String hora) {
    if (hora == null) {
        return "";
    }

    hora = hora.trim();

    if (hora.length() == 5) {
        return hora + ":00";
    }

    if (hora.length() == 8) {
        return hora;
    }

    return hora;
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
    response.sendRedirect("turma_editar.jsp?id=" + idParam + "&erro=campos_obrigatorios");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int turmaId = Integer.parseInt(idParam);
int disciplinaId = Integer.parseInt(disciplinaParam);
int capacidadeMinima = Integer.parseInt(capacidadeMinParam);
int capacidadeMaxima = Integer.parseInt(capacidadeMaxParam);
int ativo = Integer.parseInt(ativoParam);

int horarioId = 0;

if (horarioIdParam != null && !horarioIdParam.trim().isEmpty()) {
    horarioId = Integer.parseInt(horarioIdParam);
}

String horaInicioFormatada = normalizarHora(horaInicio);
String horaFimFormatada = normalizarHora(horaFim);

if (capacidadeMaxima < capacidadeMinima) {
    response.sendRedirect("turma_editar.jsp?id=" + turmaId + "&erro=capacidade_invalida");
    return;
}

if (horaFimFormatada.compareTo(horaInicioFormatada) <= 0) {
    response.sendRedirect("turma_editar.jsp?id=" + turmaId + "&erro=horario_invalido");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    /* Buscar coordenador autenticado */
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
        con.rollback();
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

    /* Confirmar que a turma pertence ao coordenador */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE t.id = ? AND d.coordenador_id = ?"
    );

    ps.setInt(1, turmaId);
    ps.setInt(2, coordenadorId);
    rs = dbQuery(con, ps);

    int turmaPermitida = 0;

    if (rs.next()) {
        turmaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (turmaPermitida == 0) {
        con.rollback();
        response.sendRedirect("turmas.jsp?erro=turma_nao_permitida");
        return;
    }

    /* Confirmar que a disciplina escolhida também pertence ao coordenador */
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
        con.rollback();
        response.sendRedirect("turma_editar.jsp?id=" + turmaId + "&erro=disciplina_nao_permitida");
        return;
    }

    /* Confirmar que a capacidade máxima não fica menor que os inscritos */
    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total_inscritos " +
        "FROM inscricoes " +
        "WHERE turma_id = ? AND estado = 'ATIVA'"
    );

    ps.setInt(1, turmaId);
    rs = dbQuery(con, ps);

    int totalInscritos = 0;

    if (rs.next()) {
        totalInscritos = rs.getInt("total_inscritos");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (capacidadeMaxima < totalInscritos) {
        con.rollback();
        response.sendRedirect("turma_editar.jsp?id=" + turmaId + "&erro=capacidade_menor_que_inscritos");
        return;
    }

    /* Atualizar turma */
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
    ps.setInt(7, turmaId);

    ps.executeUpdate();

    dbClose(null, ps, null);
    ps = null;

    /* Atualizar ou criar horário */
    if (horarioId > 0) {

        ps = con.prepareStatement(
            "UPDATE horarios " +
            "SET dia_semana = ?, hora_inicio = ?, hora_fim = ?, sala = ? " +
            "WHERE id = ? AND turma_id = ?"
        );

        ps.setString(1, diaSemana.trim());
        ps.setString(2, horaInicioFormatada);
        ps.setString(3, horaFimFormatada);
        ps.setString(4, sala.trim());
        ps.setInt(5, horarioId);
        ps.setInt(6, turmaId);

        ps.executeUpdate();

    } else {

        ps = con.prepareStatement(
            "INSERT INTO horarios " +
            "(turma_id, dia_semana, hora_inicio, hora_fim, sala) " +
            "VALUES (?, ?, ?, ?, ?)"
        );

        ps.setInt(1, turmaId);
        ps.setString(2, diaSemana.trim());
        ps.setString(3, horaInicioFormatada);
        ps.setString(4, horaFimFormatada);
        ps.setString(5, sala.trim());

        ps.executeUpdate();
    }

    con.commit();

    response.sendRedirect("turmas.jsp?sucesso=turma_atualizada");
    return;

} catch (Exception e) {

    if (con != null) {
        try {
            con.rollback();
        } catch (Exception ignored) {}
    }

    out.print("<h2>Erro ao atualizar turma</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='turma_editar.jsp?id=" + turmaId + "'>Voltar</a>");

} finally {

    if (con != null) {
        try {
            con.setAutoCommit(true);
        } catch (Exception ignored) {}
    }

    dbClose(rs, ps, con);
}
%>