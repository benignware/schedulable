require 'test_helper'

class TestEventsControllerTest < ActionController::TestCase
  setup do
    @test_event = test_events(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:test_events)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create test_event" do
    assert_difference('TestEvent.count') do
      post :create, test_event: { date: @test_event.date, time: @test_event.time }
    end

    assert_redirected_to test_event_path(assigns(:test_event))
  end

  test "should show test_event" do
    get :show, id: @test_event
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @test_event
    assert_response :success
  end

  test "should update test_event" do
    patch :update, id: @test_event, test_event: { date: @test_event.date, time: @test_event.time }
    assert_redirected_to test_event_path(assigns(:test_event))
  end

  test "should destroy test_event" do
    assert_difference('TestEvent.count', -1) do
      delete :destroy, id: @test_event
    end

    assert_redirected_to test_events_path
  end
end
