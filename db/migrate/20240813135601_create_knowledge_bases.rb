class CreateKnowledgeBases < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_bases do |t|
      t.string :question
      t.string :thought
      t.string :action
      t.string :observation
      t.string :answer

      t.timestamps
    end
  end
end
