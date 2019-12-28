class ListArticlesController < ApplicationController
	before_action :authenticate_user!, :except => [ :feed ]
  def index
		@allArticles = current_user.articles
  end

  def feed
    @page = params[:page] ? params[:page].to_i : 0
    @page = @page >= 0 ? @page : 0

    @articles = Article.where({ :visibility => 0 }).limit(20).offset(@page * 20)
    if current_user != nil
      @articles = Article.where({ :visibility => 0 }).where.not({ user_id: current_user.id }).limit(20).offset(@page * 20)
    end

    @page = @page + 1

    # decide whether to show the next page
    @show_next_page = true
    if @articles.count < 20
      @show_next_page = false
    end
  end
end
