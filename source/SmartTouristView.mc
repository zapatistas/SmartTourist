import Toybox.Graphics;
import Toybox.WatchUi;

class SmartTouristView extends WatchUi.View {
    var startText;
    var heartR;
    var stringHr;
    var height;
    var width;
    
    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.height = dc.getHeight();
        self.width = dc.getWidth();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        
        self.startText = new WatchUi.Text({
            :text=>"Start.",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_LARGE,//, Graphics.FONT_SMALL, Graphics.FONT_XTINY],
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_TOP,
           
        });

        self.stringHr = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_MEDIUM,//, Graphics.FONT_SMALL, Graphics.FONT_XTINY],
            :locX => 15,
            :locY=>(self.height/2),
           
        });
        

        self.heartR  = new WatchUi.Text({
            
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_MEDIUM,
            :locX => (self.width/2) + 10,
            :locY=> (self.height/2),
           
        });

        // self.stringTemp= new WatchUi.Text({
        //     :text=>"",
        //     :color=>Graphics.COLOR_WHITE,
        //     :font=>Graphics.FONT_MEDIUM,//, Graphics.FONT_SMALL, Graphics.FONT_XTINY],
        //     :locX => 10,
        //     :locY=>(self.height/2),
           
        // });
        

        // self.temp  = new WatchUi.Text({
            
        //     :text=>"",
        //     :color=>Graphics.COLOR_WHITE,
        //     :font=>Graphics.FONT_MEDIUM,
        //     :locX => (self.width/2) + 10,
        //     :locY=> (self.height/2),
           
        // });


    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        
        View.onUpdate(dc);
        self.startText.draw(dc);
        self.stringHr.draw(dc);
        self.heartR.draw(dc); 
        
    }

    // function update(){
    
    // }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
