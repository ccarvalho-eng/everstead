defmodule EversteadWeb.PageController do
  use EversteadWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
