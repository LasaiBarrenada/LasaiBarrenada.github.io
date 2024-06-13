library(ggmap)
library(ggplot2)
library(dplyr)
library(openxlsx)
library(tidygeocoder)
library(tidyverse)
# library(leaflet)
library(sf)
library(maps)
library(ggpubr)
world <- map_data('world')

conferences <- read.xlsx("conferences.xlsx")
geocoded_cities <- tidygeocoder::geocode(.tbl = conferences,city = Location)

my_uni <- tidygeocoder::geocode(.tbl = data.frame(Location = "Leuven"), city = Location)

p <- ggplot(geocoded_cities) + 
  geom_map(data = world, map = world,
           aes(group = group, map_id = region),
           fill = "white", color = "#7f7f7f", size = 0.5) +
  geom_label(data = geocoded_cities, aes(x = long, y = lat,label =paste(Code_Name, Year)),
             size = 3,nudge_y = 2.5) +
  geom_point(data = geocoded_cities, aes(x = long, y = lat),size = 2) +
  geom_label(data = my_uni, aes(x = long, y = lat),
             size = 3,nudge_y = 2.5,nudge_x = 2, label = "KU Leuven", color =  "blue1")+
  geom_point(data = my_uni,aes(x = long, y = lat),size = 2, color = "blue1")+
  
  coord_fixed(clip = "on",expand = T,xlim= c(min(geocoded_cities$long)-10,max(geocoded_cities$long)+10),
              ylim = c(min(geocoded_cities$lat)-5,max(geocoded_cities$lat)+5)) +
  xlab("")+ylab("")+ theme(axis.text = element_blank(),
                           axis.ticks = element_blank())

ggsave("map_plot.png",plot = p,dpi = 600)

library(magick)
map <- image_read("map_plot.png")
map <- image_trim(map)
image_write(map, "map_plot.png",format = "png",quality = 100)
