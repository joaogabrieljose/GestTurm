<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Novo Utilizador - Gesturma</title>
    <link rel="stylesheet" href="../../css/geral.css">
</head>

<body>

<div class="dashboard-container">

    <aside class="sidebar">
        <div class="brand">
            <div class="brand-icon">G</div>
            <span>Gesturma</span>
        </div>

        <nav class="menu">
            <a href="admin.jsp">Dashboard</a>
            <a href="utilizadores.jsp" class="active">Utilizadores</a>
            <a href="disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>
    </aside>

    <main class="main-content">

        <section class="page-header">
            <h1>Novo Utilizador</h1>
            <p>Preenche os dados para criar um novo utilizador no Gesturma.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="utilizador_guardar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome completo</label>
                            <input type="text" name="nome" required>
                        </div>

                        <div class="form-group">
                            <label>Email</label>
                            <input type="email" name="email" required>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <input type="password" name="password" required>
                        </div>

                        <div class="form-group">
                            <label>Perfil</label>
                            <select name="perfil" id="perfilSelect" required>
                                <option value="">Selecionar perfil</option>
                                <option value="ADMINISTRADOR">Administrador</option>
                                <option value="COORDENADOR">Coordenador</option>
                                <option value="ALUNO">Aluno</option>
                            </select>
                        </div>

                        <div class="form-group perfil-extra aluno-extra">
                            <label>Número de aluno</label>
                            <input type="text" name="numero_aluno">
                        </div>

                        <div class="form-group perfil-extra aluno-extra coordenador-extra">
                            <label>Curso</label>
                            <input type="text" name="curso">
                        </div>

                        <div class="form-group perfil-extra aluno-extra">
                            <label>Ano curricular</label>
                            <input type="number" name="ano_curricular" min="1" max="5">
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1">Ativo</option>
                                <option value="0">Inativo</option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="utilizadores.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Guardar Utilizador
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<script>
    const perfilSelect = document.getElementById("perfilSelect");
    const extras = document.querySelectorAll(".perfil-extra");
    const alunoExtras = document.querySelectorAll(".aluno-extra");
    const coordenadorExtras = document.querySelectorAll(".coordenador-extra");

    function atualizarCamposPerfil() {
        extras.forEach(function(campo) {
            campo.style.display = "none";
        });

        if (perfilSelect.value === "ALUNO") {
            alunoExtras.forEach(function(campo) {
                campo.style.display = "block";
            });
        }

        if (perfilSelect.value === "COORDENADOR") {
            coordenadorExtras.forEach(function(campo) {
                campo.style.display = "block";
            });
        }
    }

    perfilSelect.addEventListener("change", atualizarCamposPerfil);
    atualizarCamposPerfil();
</script>

</body>
</html>