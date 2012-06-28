class OverridesController < ApplicationController
  
  def index
    @overrides = Override.default_order.paginate :page => params[:page]
  end
  
  def new
    @override = Override.new
  end
  
  def create
    @override = Override.new params[:override]

    if @override.save
      redirect_to(overrides_path, :notice => 'Override was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @override = Override.find params[:id]
  end

  def update
    @override = Override.find(params[:id])

    if @override.update_attributes(params[:override])
      redirect_to(edit_override_path(@override), :notice => 'Override was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @override = Override.find params[:id]
    @override.destroy
    
    redirect_to overrides_url
  end
end
