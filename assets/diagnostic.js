document.addEventListener("DOMContentLoaded", () => {
  const button = document.querySelector("#diagnostic-submit");
  const result = document.querySelector("#diagnostic-result");
  if (!button || !result) return;

  button.addEventListener("click", () => {
    const questions = [...document.querySelectorAll(".diagnostic-quiz")];
    const scores = { r: 0, modeles: 0, validation: 0 };
    const totals = { r: 0, modeles: 0, validation: 0 };
    let answered = 0;

    questions.forEach((question) => {
      const category = question.dataset.category;
      const answer = question.dataset.answer;
      const selected = question.querySelector("input:checked");
      totals[category] += 1;
      if (selected) {
        answered += 1;
        if (selected.value === answer) scores[category] += 1;
      }
    });

    if (answered < questions.length) {
      result.innerHTML = "Répondez aux neuf questions pour obtenir votre portrait de départ.";
      result.classList.add("visible");
      return;
    }

    const recommendation = [];
    if (scores.r < 2) recommendation.push("Commencez par la page Préparation et le rappel R.");
    if (scores.modeles < 2) recommendation.push("Prenez le temps de faire le tutoriel du jour 1 avant le défi.");
    if (scores.validation < 2) recommendation.push("Gardez l'aide-mémoire sur les données d'entraînement, de validation et de test à portée de main.");
    if (recommendation.length === 0) recommendation.push("Vous êtes prêt ou prête pour les défis avancés et les extensions.");

    result.innerHTML = `
      <p>R et données: ${scores.r}/${totals.r}</p>
      <p>Modèles: ${scores.modeles}/${totals.modeles}</p>
      <p>Validation: ${scores.validation}/${totals.validation}</p>
      <p>${recommendation.join(" ")}</p>
    `;
    result.classList.add("visible");
  });
});
