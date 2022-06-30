/**
* Name: NewModel
* Based on the internal skeleton template. 
* Author: LeonNguyen
* Tags: 
*/

model traffic

global {
	shape_file buildings_shape_file <- shape_file("../includes/buildings.shp");
	shape_file roads_shape_file <- shape_file("../includes/roads.shp");
	geometry shape <- envelope(roads_shape_file);
	float people_m2 <- 0.001;
	float step <- 10#s;
	graph road_network;
	map<road, float> road_weights;
	
	field pollution_field <- field(50,50,0);
	
	reflex pollution{
		pollution_field[rnd(50),rnd(50),0] <- rnd(100);	
	}
	
	reflex update_weight{
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);
	}
	
	
	init{
		create building from: buildings_shape_file with:(height: float(get("HEIGHT")));
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
		
		ask building{
			int num_to_create <- round(people_m2*shape.area);
			create inhabitant number:num_to_create{
				location <- any_location_in(one_of(myself));
			}
		
		}
		
		
	}

}

species building{
	int height;
	
	aspect default{
		draw shape color: #gray;
	}

	aspect threeD{
		draw shape depth: height texture: ["../includes/roof_top.png","../includes/texture5.jpg"];
	}
	
}

species road{
	float capacity <- 1 + shape.perimeter/30;
	int nb_drivers <- 0 update: length(inhabitant at_distance 1#m); //
	float speed_rate <- 1.0 update: exp(-nb_drivers/capacity) min: 0.1;
	
	aspect default{
		draw shape buffer ((1- speed_rate)*5) color: #red;
	}
}


species inhabitant skills:[moving]{
	point target;
	rgb color <- rnd_color(255);
	float proba_leave <- 0.05;
	float speed <- 5 #km/#h;
	float pollution_produced <- rnd(90.0,250.0);
	
	reflex leave when: target = nil and flip(proba_leave){
		target <- any_location_in(one_of(building));
		write name + " " + target;
	}
	
	reflex move when: target != nil{
		do goto target: target on: road_network move_weights: road_weights;
		if (location = target){
			target <- nil;
		} else{
			pollution_cell my_cell <- pollution_cell(location);
			my_cell.grid_value <- my_cell.grid_value + pollution_produced; 
		}
	}
	
	
	aspect default{
		draw circle(5) color:color;
	}
	
	aspect threeD{
		draw pyramid(4) color: color;
		draw sphere(1) at: location+ {0,0,4} color:color;
	}
}

grid pollution_cell width: 50 height: 50 {
	
	reflex decrease_pollution when: every(1 #h){
		grid_value <- grid_value*0.9;
	}
}


experiment traffic type: gui {
	output {
	
		display map type:opengl{
			mesh pollution_cell color: #red transparency: 0.5 scale: 0.05 triangulation: true smooth: true refresh: true; 
			species building aspect: default;
			species road aspect: default;
			species inhabitant aspect: default;
		}
	
		 
			}
}