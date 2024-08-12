Plasma Reddit Wallpaper plugin 

Greatly inspired by https://github.com/Zren/plasma-wallpapers
Porting to Qt6 and Plasma/KDE 6 greatly inspired by https://github.com/bouteillerAlan/blurredwallpaper

!! If you need the Plasma5 version checkout the plasma5 branch instead and follow the readme there. !!

!! From now on the plugin only works on Qt6 and KDE/Plasma 6. !!

In config : 

* choose a subreddit (pick one with many pictures like EarthPorn for example otherwise no pic can be fetched)
* choose the delay between two wallpapers change
* and that should be it

The picture or thread title is displayed at the bottom, to have informations about the picture.

[Screenshot](Screenshot_1.png)


[Screenshot](Screenshot_2.png)

To install just run the `./install` script, it will use the zip provided with the code.

To uninstall just run from this repo root : 

```shell
kpackagetool6 -t "Plasma/Wallpaper" -r package
```

