class ConsultationController < ApplicationController
  def index; end

  def chat
    question = params[:question]
    answer = Llm::Deliver.answer(question)

    render json: { answer: answer }, status: :created
  end
end
