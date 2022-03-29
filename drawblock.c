#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>

#define STR_LEN 1024

struct state {
	int X;
	int Y;
	int H;
	int W;
	int MODX;
	int MODY;
	char path[STR_LEN];
	char buffer[STR_LEN];
	char invertbuffer[STR_LEN];
	int row;
	int col;
	int filmheight;
	int frame;
	FILE *invertlayer;
} s;

int min(int a, int b) {
	return (a > b) ? b : a;
}

int linecount(char* filename, char* buffer) {
	FILE *fp = fopen(filename, "r");
	if (fp == NULL) {
		printf("Failed to open file %s for reading\n", filename);
		return 1;
	}

	int lc = 0;
	while (fgets(buffer, STR_LEN, fp))
		lc++;

	fclose(fp);

	return lc;
}

void drawlayer (struct state) {
	FILE *layer = fopen(s.path, "r");
	if (layer == NULL) {
		return;
	}

	int lineno = s.row + s.Y + s.MODY; /* reset lineno */
	int xpos = s.col + s.X + s.MODX;
	int ltrim = 0;
	if (xpos <= 0)
		ltrim = xpos * -1 + 1;

	/* get the film frame count */
	int filmframecount;
	if (s.filmheight > 0) {
		filmframecount = (linecount(s.path, s.buffer) - 5) / s.filmheight;
	} else {
		filmframecount = 1;
	}

	/* read the layer's header */
	fgets(s.buffer, STR_LEN, layer); int fg = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, layer); int bg = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, layer); char attr[STR_LEN]; strcpy(attr, s.buffer);
	fgets(s.buffer, STR_LEN, layer); int filmtime = atoi(s.buffer);
	/* filmshownframe is more complex than the above few */
	int filmshownframe;
	fgets(s.buffer, STR_LEN, layer);
	if (! s.frame || filmtime <= 0)
		filmshownframe = 1;
	else {
		switch (atoi(s.buffer)) {
			case 0: filmshownframe = (min(s.frame, filmframecount * filmtime)) / filmtime;
			case 1: filmshownframe = (s.frame % (filmframecount * filmtime)) / filmtime;
		}
	}

	/* read metalayers */
	if (s.invertlayer) fseek(s.invertlayer, 0, SEEK_SET);

	int drawnlines = 0;
	int processedlines = 0;
	int i;
	while (fgets(s.buffer, STR_LEN, layer)) {
		if (s.invertlayer) fgets(s.invertbuffer, STR_LEN, s.invertlayer);

		/* burn through lines until the wanted frame is queued */
		processedlines++;
		if (filmshownframe >= 1 && processedlines <= (filmshownframe * s.filmheight)) continue;

		if (lineno > s.H) break; /* finish before lines are drawn off screen */
		if (lineno >= 1) { /* start when lines are being drawn on screen */
			/* stop after drawing a full frame */
			drawnlines++;
			if (s.filmheight > 0 && drawnlines > s.filmheight) break;

			// set text formatting opts
			printf("\033[%s;3%d;4%dm", attr, fg, bg);
			// draw the block
			for (i = 0; i < strlen(s.buffer); i++) {
				if (xpos + i > s.X && xpos + i < s.X + s.W) {
					if (s.buffer[i] != ' ') {
						if (s.invertlayer && s.invertbuffer[i] && s.invertbuffer[i] != ' ') {
							printf("\033[%s;7;3%d;4%dm", attr, fg, bg); /* add the invert attribute */
							printf("\033[%d;%dH%c", lineno, xpos + i, s.buffer[i]);
							printf("\033[%s;3%d;4%dm", attr, fg, bg); /* remove the invert attribute */
						} else printf("\033[%d;%dH%c", lineno, xpos + i, s.buffer[i]);
					}
				}
			}
			// unset text formatting opt
			printf("\033[0m");
		}
		lineno++;
	}
	fclose(layer);
}

int main(int argc, char *argv[]) {
	if (argv[1] == NULL) {
		printf("Missing args\n");
		return 1;
	}

	char dirpath[STR_LEN];

	/* CONFIG FILE */
	strcpy(s.path, argv[1]);
	FILE *config = fopen(strcat(s.path, "/config"), "r");
	if (config == NULL) {
		printf("Failed to open config file\n");
		return 1;
	}

	/* there's always the same amount of fields to read */
	fgets(s.buffer, STR_LEN, config); s.row = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, config); s.col = atoi(s.buffer);
	fgets(s.buffer, STR_LEN, config); s.filmheight = atoi(s.buffer);

	s.X = atoi(getenv("X"));
	s.Y = atoi(getenv("Y"));
	s.H = atoi(getenv("H"));
	s.W = atoi(getenv("W"));
	s.MODX = atoi(getenv("MODX"));
	s.MODY = atoi(getenv("MODY"));

	/* completely off screen checks */
	if (s.row + s.Y + s.MODY > s.H) return 0;
	if (s.col + s.X + s.MODX > s.W) return 0;

	fclose(config);

	/* META LAYERS */
	strcpy(s.path, argv[1]);
	s.invertlayer = fopen(strcat(s.path, "/invert"), "r");

	/* LAYER FILES */
	s.frame = atoi(argv[2]);
	strcpy(s.path, argv[1]); strcat(s.path, "/0"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/1"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/2"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/3"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/4"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/5"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/6"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/7"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/8"); drawlayer(s);
	strcpy(s.path, argv[1]); strcat(s.path, "/9"); drawlayer(s);

	if (s.invertlayer)
		fclose(s.invertlayer);
	return 0;
}
