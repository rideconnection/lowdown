class ProgramsController < ApplicationController
  
  before_filter :require_admin_user, :except => [:index, :edit]

  def index
    @programs = Program.default_order.paginate :page => params[:page]
  end
  
  def new
    @program = Program.new
  end
  
  def create
    @program = Program.new params[:program]

    if @program.save
      redirect_to(programs_path, :notice => 'Program was successfully created.')
    else
      render :action => "new"
    end
  end

  def edit
    @program = Program.find params[:id]
  end

  def update
    @program = Program.find(params[:id])

    if @program.update_attributes(params[:program])
      redirect_to(edit_program_path(@program), :notice => 'Program was successfully updated.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @program = Program.find params[:id]
    @program.destroy
    
    redirect_to programs_url
  end
end
