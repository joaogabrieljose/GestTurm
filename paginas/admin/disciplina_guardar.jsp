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

String nome = request.getParameter("nome");
String codigo = request.getParameter("codigo");
String coordenadorParam = request.getParameter("coordenador_id");
String semestreParam = request.getParameter("semestre");
String anoLetivo = request.getParameter("ano_letivo");
String numeroAlunosParam = request.getParameter("numero_alunos_inscritos");
String ativoParam = request.getParameter("ativo");

if (
    nome == null || nome.trim().isEmpty() ||
    codigo == null || codigo.trim().isEmpty() ||
    coordenadorParam == null || coordenadorParam.trim().isEmpty() ||
    semestreParam == null || semestreParam.trim().isEmpty() ||
    anoLetivo == null || anoLetivo.trim().isEmpty() ||
    numeroAlunosParam == null || numeroAlunosParam.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty()
) {
    response.sendRedirect("disciplina_criar.jsp?erro=campos_obrigatorios");
    return;
}

int coordenadorId = Integer.parseInt(coordenadorParam);
int semestre = Integer.parseInt(semestreParam);
int numeroAlunos = Integer.parseInt(numeroAlunosParam);
int ativo = Integer.parseInt(ativoParam);

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "INSERT INTO disciplinas " +
        "(coordenador_id, nome, codigo, semestre, ano_letivo, numero_alunos_inscritos, ativo) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)"
    );

    ps.setInt(1, coordenadorId);
    ps.setString(2, nome.trim());
    ps.setString(3, codigo.trim().toUpperCase());
    ps.setInt(4, semestre);
    ps.setString(5, anoLetivo.trim());
    ps.setInt(6, numeroAlunos);
    ps.setInt(7, ativo);

    ps.executeUpdate();

    response.sendRedirect("disciplinas.jsp?sucesso=disciplina_criada");
    return;

} catch (Exception e) {
    out.print("Erro ao guardar disciplina: " + e.getMessage());

} finally {
    dbClose(null, ps, con);
}
%>