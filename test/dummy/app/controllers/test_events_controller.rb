class TestEventsController < ApplicationController
  before_action :set_test_event, only: [:show, :edit, :update, :destroy]

  # GET /test_events
  def index
    @test_events = TestEvent.all
  end

  # GET /test_events/1
  def show
  end

  # GET /test_events/new
  def new
    @test_event = TestEvent.new
  end

  # GET /test_events/1/edit
  def edit
  end

  # POST /test_events
  def create
    @test_event = TestEvent.new(test_event_params)

    if @test_event.save
      redirect_to @test_event, notice: 'Test event was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /test_events/1
  def update
    if @test_event.update(test_event_params)
      redirect_to @test_event, notice: 'Test event was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /test_events/1
  def destroy
    @test_event.destroy
    redirect_to test_events_url, notice: 'Test event was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_test_event
      @test_event = TestEvent.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def test_event_params
      params.require(:test_event).permit(:date, :time)
    end
end
