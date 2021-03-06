class MeasurementsController < ApplicationController
  before_action :authenticate_user!, except: [:index_measurements_public_sensor, :create_by_sensor]
  before_action :get_sensor, except: [:create_by_sensor]
  before_action :set_measurement, only: %i[ show edit update destroy ]
  skip_before_action :verify_authenticity_token, only: [:create_by_sensor]
  # GET /measurements or /measurements.json
  #
  def index
    @measurements = @sensor.measurements.order_most_recent
    @data = @measurements.chart_data(params[:format])
    @label = str_label(params[:format])
    @alarm=false
    if @sensor.notifica_down
    then
      @recent=@sensor.measurements.recent(@sensor.tdown.hours.ago)
      if @recent.blank?
        then @alarm=true
      end
    end
  end

  def index_measurements_public_sensor
    if @sensor.public == true
       @measurements = @sensor.measurements.order_most_recent
       @data = @measurements.chart_data(params[:format])
       @label = str_label(params[:format])
    else
      @measurements = nil
    end
  end

  # GET /measurements/1 or /measurements/1.json
  def show
  end


  # GET /measurements/new
  def new
    @measurement = @sensor.measurements.build
  end

  # GET /measurements/1/edit
  def edit
  end

  # POST /measurements or /measurements.json
  def create
    @measurement = @sensor.measurements.build(measurement_params)
    create_respond
  end

  def create_by_sensor
    #sid = Sensor.where(URI: measurement_params[:sensor_uri]).pluck(:id).first
    #mp1 = measurement_params.merge(sensor_id: sid)
    #mp2 = mp1.extract!(:sensor_uri)
    #@measurement = Measurement.new(mp1)
    @sensor = Sensor.find_by_URI(measurement_params[:sensor_uri])
    if @sensor.auth_token == measurement_params[:auth_token]
      then
      @measurement = @sensor.measurements.build(measurement_params.except(:sensor_uri,:auth_token))
      create_respond
    else
      respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /measurements/1 or /measurements/1.json
  def update
    mp1 = measurement_params
    mp2 = mp1.extract!(:sensor_uri)
    respond_to do |format|
     if @measurement.update(mp1)
        format.html { redirect_to sensor_measurements_path(@sensor), notice: "Measurement was successfully updated." }
        format.json { render :show, status: :ok, location: @measurement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @measurement.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /measurements/1 or /measurements/1.json
  def destroy
    @measurement.destroy
    respond_to do |format|
      format.html { redirect_to sensor_measurements_path(@sensor), notice: "Measurement was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measurement
      @measurement = @sensor.measurements.find(params[:id])
    end

    def get_sensor
      @sensor = Sensor.find(params[:sensor_id])
    end

    # Only allow a list of trusted parameters through.
    def measurement_params
      params.require(:measurement).permit(:timestamp, :value, :sensor_uri, :sensor_id, :auth_token)
    end

  def create_respond
    respond_to do |format|
      if @measurement.save
        format.html { redirect_to sensor_measurements_path(@sensor), notice: "Measurement was successfully created." }
        format.json { render :show, status: :created, location: @measurement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  def str_label(label)
    case label
    when "1_week"
      "1 week ago"
    when "24_hours"
      "24 hours ago"
    when "1_month"
      "1 month ago"
    when "full"
      "Full period"
    else
      "1 week ago"
    end
  end
end
