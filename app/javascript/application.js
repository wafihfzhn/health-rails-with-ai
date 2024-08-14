// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "controllers";
import "@hotwired/turbo-rails";

document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("form");
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const answerElement = document.getElementById("answer");
    const submitButton = form.querySelector("input[type='submit']");
    const question = form.querySelector("input[name='question']").value;

    submitButton.disabled = true;
    submitButton.value = "Mencari Jawaban...";
    answerElement.textContent = "Sedang mencari jawaban yang cocok untukmu..."
    fetch(form.action, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ question: question })
    })
    .then(response => response.json())
    .then(data => {
      let index = 0;
      const answer = data.answer;
      answerElement.textContent = '';

      function typeEffect() {
        if (index < answer.length) {
          answerElement.textContent += answer.charAt(index);
          index++;
          setTimeout(typeEffect, 20);
        }
      }

      typeEffect();
    })
    .finally(() => {
      submitButton.disabled = false;
      submitButton.value = "Send";
    });
  });
});
