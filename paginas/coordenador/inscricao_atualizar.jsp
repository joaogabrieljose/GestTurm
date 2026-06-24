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
String turmaParam = request.getParameter("turma_id");
String estado = request.getParameter("estado");

if (
    idParam == null || idParam.trim().isEmpty() ||
    turmaParam == null || turmaParam.trim().isEmpty() ||
    estado == null || estado.trim().isEmpty()
) {
    response.sendRedirect("inscricoes.jsp?erro=campos_obrigatorios");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int inscricaoId = Integer.parseInt(idParam);
int novaTurmaId = Integer.parseInt(turmaParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "i.disciplina_id, i.estado AS estado_atual " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE i.id = ? " +
        "AND u.id = ? " +
        "AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, inscricaoId);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    int disciplinaId = 0;
    String estadoAtual = "";

    if (rs.next()) {
        disciplinaId = rs.getInt("disciplina_id");
        estadoAtual = rs.getString("estado_atual");
    } else {
        response.sendRedirect("inscricoes.jsp?erro=inscricao_nao_permitida");
        return;
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE t.id = ? " +
        "AND t.disciplina_id = ? " +
        "AND t.ativo = 1 " +
        "AND u.id = ? " +
        "AND u.perfil = 'COORDENADOR'"
    );

    ps.setInt(1, novaTurmaId);
    ps.setInt(2, disciplinaId);
    ps.setInt(3, userId);
    rs = dbQuery(con, ps);

    int turmaPermitida = 0;

    if (rs.next()) {
        turmaPermitida = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (turmaPermitida == 0) {
        response.sendRedirect("inscricao_editar.jsp?id=" + inscricaoId + "&erro=turma_nao_permitida");
        return;
    }

    if ("ATIVA".equalsIgnoreCase(estado)) {

        if (!"ATIVA".equalsIgnoreCase(estadoAtual)) {
            ps = con.prepareStatement(
                "SELECT COUNT(*) AS total " +
                "FROM periodos_inscricao " +
                "WHERE disciplina_id = ? " +
                "AND ativo = 1 " +
                "AND NOW() BETWEEN data_inicio AND data_fim"
            );

            ps.setInt(1, disciplinaId);
            rs = dbQuery(con, ps);

            int periodoAberto = 0;

            if (rs.next()) {
                periodoAberto = rs.getInt("total");
            }

            dbClose(rs, ps, null);
            rs = null;
            ps = null;

            if (periodoAberto == 0) {
                response.sendRedirect("inscricao_editar.jsp?id=" + inscricaoId + "&erro=periodo_fechado");
                return;
            }
        }

        ps = con.prepareStatement(
            "SELECT " +
            "t.capacidade_maxima, " +
            "COALESCE(ins.total_inscritos, 0) AS total_inscritos " +
            "FROM turmas t " +
            "LEFT JOIN ( " +
            "   SELECT turma_id, COUNT(*) AS total_inscritos " +
            "   FROM inscricoes " +
            "   WHERE estado = 'ATIVA' " +
            "   AND id <> ? " +
            "   GROUP BY turma_id " +
            ") ins ON ins.turma_id = t.id " +
            "WHERE t.id = ?"
        );

        ps.setInt(1, inscricaoId);
        ps.setInt(2, novaTurmaId);
        rs = dbQuery(con, ps);

        if (rs.next()) {
            int capacidadeMaxima = rs.getInt("capacidade_maxima");
            int totalInscritos = rs.getInt("total_inscritos");

            if (totalInscritos >= capacidadeMaxima) {
                response.sendRedirect("inscricao_editar.jsp?id=" + inscricaoId + "&erro=turma_cheia");
                return;
            }
        }

        dbClose(rs, ps, null);
        rs = null;
        ps = null;
    }

    ps = con.prepareStatement(
        "UPDATE inscricoes " +
        "SET turma_id = ?, estado = ? " +
        "WHERE id = ?"
    );

    ps.setInt(1, novaTurmaId);
    ps.setString(2, estado.trim());
    ps.setInt(3, inscricaoId);

    ps.executeUpdate();

    response.sendRedirect("inscricoes.jsp?sucesso=inscricao_atualizada");
    return;

} catch (Exception e) {

    out.print("<h2>Erro ao atualizar inscrição</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='inscricao_editar.jsp?id=" + inscricaoId + "'>Voltar</a>");

} finally {
    dbClose(rs, ps, con);
}
%>