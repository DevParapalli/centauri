// A slide whose content runs onto a second page stops the build.
#import "/lib.typ": *
#show: centauri.with(kind: "deck")
#claim(title: [Too much text])[#for i in range(40) [Line #i \ ]]
