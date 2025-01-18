# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Jeoparty.Repo.insert!(%Jeoparty.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Jeoparty.Repo
alias Jeoparty.Accounts
alias Jeoparty.GameGrids
alias Jeoparty.Question.Cell

# Create a test admin user
{:ok, admin} = Accounts.register_user(%{
  email: "admin@admin.com",
  password: "admin"
})

# Create a test game grid
{:ok, game_grid} = GameGrids.create_game_grid(%{
  name: "Test Game",
  columns: 4,
  rows: 4,
  created_by: admin.id
})

# Categories
categories = [
  %{
    column: 1,
    question: "World Capitals"
  },
  %{
    column: 2,
    question: "Famous Scientists"
  },
  %{
    column: 3,
    question: "Internet Culture"
  },
  %{
    column: 4,
    question: "Space Exploration"
  }
]

# Create categories (first row)
Enum.each(categories, fn category ->
  GameGrids.create_cell(%{
    row: 1,
    column: category.column,
    game_grid_id: game_grid.id,
    type: "text",
    data: %{
      "question" => category.question
    }
  })
end)

# Questions for World Capitals
world_capitals = [
  %{
    row: 2,
    points: 100,
    question: "This city, known as the 'City of Light', became France's capital in 987 CE",
    answer: "What is Paris?",
    type: "text"
  },
  %{
    row: 3,
    points: 200,
    question: "This Asian capital's name means 'Eastern Capital'",
    answer: "What is Tokyo?",
    type: "picture",
    image_url: "https://upload.wikimedia.org/wikipedia/commons/b/b2/Skyscrapers_of_Shinjuku_2009_January.jpg"
  },
  %{
    row: 4,
    points: 300,
    question: "This capital city sits at the highest elevation of any capital in Europe",
    answer: "What is Andorra la Vella?",
    type: "text"
  }
]

# Questions for Famous Scientists
scientists = [
  %{
    row: 2,
    points: 100,
    question: "This scientist developed the theory of general relativity",
    answer: "Who is Albert Einstein?",
    type: "picture",
    image_url: "https://upload.wikimedia.org/wikipedia/commons/3/3e/Einstein_1921_by_F_Schmutzer_-_restoration.jpg"
  },
  %{
    row: 3,
    points: 200,
    question: "She won Nobel Prizes in both Physics and Chemistry",
    answer: "Who is Marie Curie?",
    type: "text"
  },
  %{
    row: 4,
    points: 300,
    question: "This astrophysicist hosted the reboot of Cosmos",
    answer: "Who is Neil deGrasse Tyson?",
    type: "video",
    video_url: "https://www.youtube.com/watch?v=jRQzl8ewDMQ"
  }
]

# Questions for Internet Culture
internet_culture = [
  %{
    row: 2,
    points: 100,
    question: "This 2011 video of a feline playing piano became a viral sensation",
    answer: "What is Keyboard Cat?",
    type: "video",
    video_url: "https://www.youtube.com/watch?v=J---aiyznGQ"
  },
  %{
    row: 3,
    points: 200,
    question: "This meme features a boyfriend looking back at another woman",
    answer: "What is the Distracted Boyfriend meme?",
    type: "picture",
    image_url: "https://upload.wikimedia.org/wikipedia/commons/3/3c/Distracted_boyfriend_meme_2.jpg"
  },
  %{
    row: 4,
    points: 300,
    question: "This cryptocurrency featuring a Shiba Inu started as a joke",
    answer: "What is Dogecoin?",
    type: "text"
  }
]

# Questions for Space Exploration
space = [
  %{
    row: 2,
    points: 100,
    question: "This rover has been exploring Mars since 2012",
    answer: "What is Curiosity?",
    type: "picture",
    image_url: "https://upload.wikimedia.org/wikipedia/commons/f/f3/Curiosity_Self-Portrait_at_%27Big_Sky%27_Drilling_Site.jpg"
  },
  %{
    row: 3,
    points: 200,
    question: "First human to walk on the moon",
    answer: "Who is Neil Armstrong?",
    type: "video",
    video_url: "https://www.youtube.com/watch?v=S9HdPi9Ikhk"
  },
  %{
    row: 4,
    points: 300,
    question: "This company landed two rockets simultaneously in 2018",
    answer: "What is SpaceX?",
    type: "text"
  }
]

# Helper function to create questions for a category
create_category_questions = fn questions, column ->
  Enum.each(questions, fn q ->
    GameGrids.create_cell(%{
      row: q.row,
      column: column,
      game_grid_id: game_grid.id,
      type: q.type,
      data: %{
        "question" => q.question,
        "answer" => q.answer,
        "points" => q.points,
        "image_url" => Map.get(q, :image_url),
        "video_url" => Map.get(q, :video_url)
      }
    })
  end)
end

# Create all questions
create_category_questions.(world_capitals, 1)
create_category_questions.(scientists, 2)
create_category_questions.(internet_culture, 3)
create_category_questions.(space, 4)

IO.puts("Seed data created successfully!")
