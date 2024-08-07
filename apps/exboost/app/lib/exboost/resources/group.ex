defmodule Exboost.Resources.Group do
  use Ecto.Schema
  import Ecto.Changeset
  alias Exboost.Accounts.User
  alias Exboost.Resources.Resource

  schema "groups" do
    field :name, :string

    belongs_to(:user, User)
    has_many(:resources, Resource)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
