class ArticleController < ApplicationController
  include ArticleHelper
  include ApplicationHelper
  before_action :authenticate_user!, :except => [:show]

  def index
    params[:input] = "" if params[:input] == nil
    tags, terms = understand_query(params[:input])
    if tags.length > 0 and terms.length == 0
      @searchArticles = current_user.articles.searchForTags tags
    elsif tags.length > 0 and terms.length > 0
      @searchArticles = current_user.articles.searchForTagsAndTerms tags, terms
    else
      @searchArticles = current_user.articles.search params[:input]
    end
  end

  def create
    temp = current_user.articles.create
    article_params = get_article_params(params)
    article_params.map { |k, v| temp[k] = v }

    if !temp.valid?
      redirect_to new_article_path(article_params)
      return
    end

    if temp.save!
      redirect_to root_path
    else
      render plain: "Could not save the article!"
    end
  end

  def new
    @article = { }
    @populated = (params.keys & allowed_params).count > 0

    if @populated
      @article = current_user.articles.create
      get_article_params(params).map { |k, v| @article[k] = v }
      @article.valid?
    end
  end

  def destroy
    if Article.find(params[:id]).user_id != current_user.id
      redirect_to root_path, alert: "That's not your article to edit!"
      return
    end

    if Article.find(params[:id]).delete
      redirect_to root_path, notice: "That article was deleted!"
    else
      redirect_to root_path, alert: "That article could not be deleted! Try again later."
    end
  end

  def edit
    if Article.find(params[:id]).user_id != current_user.id
      redirect_to root_path, alert: "That's not your article to edit!"
      return
    end

    @article = Article.find(params[:id])
    @article.valid?
  end

  def update
    if Article.find(params[:id]).user_id != current_user.id
      redirect_to root_path, alert: "That's not your article to edit!"
      return
    end

    temp = Article.find(params[:id])
    get_article_params(params).map { |k, v| temp[k] = v }

    if !temp.valid?
      redirect_to edit_article_path(temp), alert: "OOPS! There were errors in that article: #{temp.errors.full_messages.join '; '}"
      return
    end

    if temp.save!
      redirect_to root_path, notice: "Article updated!"
    else
      redirect_to root_path, alert: "Couldn't update that article, try again later."
    end
  end

  def show
    temp = Article.where(:id => params[:id])
    if temp.count < 1 || !show_allowed(temp[0])
      redirect_to root_path, alert: "That article doesn't exist!"
      return
    end
    @article = temp[0]

    heading = article_title @article
    quote_slice_size = 100
    quote_slice = @article.quote.slice(0, quote_slice_size) + (@article.quote.length > quote_slice_size ? "..." : "")
    desc = "Cutout from #{link_host @article}" +
      " by #{@article.user.username} on #{@article.created_at.to_date.to_formatted_s :long}." +
      " \"#{quote_slice}\""

    set_meta_tags og: { title: heading,
                        description: desc,
                        url: show_url(@article), 
                        type: "article",
                        article: {
                          author: @article.author
                        },
                        image: cutouts_show_image_url },
                        twitter: {
                          card: "summary",
                          site: "@CutoutsApp",
                          title: heading,
                          description: desc,
                          image: {
                            _: cutouts_show_image_url,
                            alt: "Scissors"
                          }
                        },
                        title: heading,
                        description: desc,
                        reverse: true
  end

  def share
    temp = Article.where(:id => params[:id])
    if temp.count >= 1
      @thisOne = temp[0]
    else
      redirect_to root_path, alert: "That article doesn't exist!"
    end
  end

  def send_share
    temp = Article.where(:id => params[:id])
    if temp.count < 1
      redirect_to root_path, alert: "That article doesn't exist!"
      return
    end
    article = temp[0]

    emails = params[:emails]
    emails = emails.split(",")
    emails = emails.map { |email| email.strip }
    valid_emails = emails.select { |email| is_valid_email(email) }

    # send emails to atmost 5 people at once
    valid_emails = valid_emails.slice(0, 5)

    # find out if this user should be cc'ed
    cc_author = params[:cc_myself]

    ArticleSharer.share_article(article,
                                valid_emails,
                                current_user,
                                params[:share_as],
                                cc_author,
                                params[:comments]).deliver

    redirect_to root_path, notice: "Article shared with #{valid_emails.join ", "}"
  end
end
