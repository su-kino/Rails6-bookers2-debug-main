class BooksController < ApplicationController
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  impressionist :actions => [:show], unique: [:session_hash]

  def show
    @book = Book.find(params[:id])
    impressionist(@book, nil, unique: [:session_hash])
    @new_book = Book.new
    @book_comment = BookComment.new
  end

  def index
    @new_book = Book.new
    if params[:sort_create]
      @books = Book.latest
    elsif params[:sort_rate]
      @books = Book.evaluation
    else
      to = Time.current.at_end_of_day
      from = (to - 6.day).at_beginning_of_day
      @books = Book.all.sort do |a, b|
        b.favorites.where(created_at: from...to).size <=>
        a.favorites.where(created_at: from...to).size
      end
    end
  end

  def create
    @new_book = Book.new(book_params)
    @new_book.user_id = current_user.id
    tag_list = params[:book][:tag_name].split(',')
    if @new_book.save
      @new_book.save_tags(tag_list)
      redirect_to book_path(@new_book), notice: "You have created book successfully."
    else
      @books = Book.all
      render 'index'
    end
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(book_params)
      redirect_to book_path(@book), notice: "You have updated book successfully."
    else
      render "edit"
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy
    redirect_to books_path
  end

  private

  def book_params
    params.require(:book).permit(:title, :body, :rate)
  end

  def ensure_correct_user
    @book = Book.find(params[:id])
    unless @book.user == current_user
      redirect_to books_path
    end
  end
end
