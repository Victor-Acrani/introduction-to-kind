package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

/*
This code is a simple example of an API with the minimal instumentation for handling requests and print logs.
No external packages are used in this example.
*/

const (
	appName         = "DEMO APP V1"
	port            = ":3000"
	shutdownTimeout = 10
)

var (
	// create custom logger
	infoLog = log.New(os.Stdout, "INFO-", log.LstdFlags|log.Lshortfile)
	errLog  = log.New(os.Stdout, "ERROR-", log.LstdFlags|log.Lshortfile)
)

// ==============================================================================
//
//	Server (demo app version 1)
//
// ==============================================================================
func main() {
	infoLog.Printf("starting %s", appName)

	// read env var
	infoLog.Printf(`got [%s] from pod ENV_VAR`, os.Getenv("ENV_VAR"))
	

	// set default handler
	http.HandleFunc("/", LogMiddleware(noRoute)) // this handle func must be the first to handle undefined paths
	http.HandleFunc("/api/v1/health", LogMiddleware(healthCheck))

	// create server
	server := &http.Server{
		Addr:         port,
		Handler:      nil,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	go func() {
		printRoutes()
		infoLog.Printf("listenning and serving on port %s", port)
		infoLog.Println(server.ListenAndServe())
	}()

	// --- gracefull shutdown ---
	// create channel to capture shutdown signal
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)

	<-shutdown

	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout*time.Second)
	defer cancel()

	err := server.Shutdown(ctx)
	if err != nil {
		errLog.Println("Server forced to shutdown")
	}

	infoLog.Printf("shutting down %s gracefully", appName)
}

func printRoutes() {
	infoLog.Println("Routes:")
	infoLog.Println("[GET] /api/v1/health")
}

// ==============================================================================
//
//	Middlewares
//
// ==============================================================================

// LogWriter gives a custom response writer.
type LogWriter struct {
	http.ResponseWriter // embed default response writer
	statusCode          int
}

// overwrite method WriteHeader
func (l *LogWriter) WriteHeader(statusCode int) {
	l.statusCode = statusCode
	l.ResponseWriter.WriteHeader(statusCode)
}

//func (l *LogWriter)

func LogMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		t := time.Now()
		infoLog.Printf("starting request [%s] %s", r.Method, r.URL)

		lw := LogWriter{ResponseWriter: w}

		next.ServeHTTP(&lw, r)

		infoLog.Printf("finishing request [%s] %s | statusCode: %d | latency: %v", r.Method, r.URL, lw.statusCode, time.Since(t))
	}
}

// ==============================================================================
//
//	handlers
//
// ==============================================================================

// healthCheck is a handle fucntion for checking is the server is up.
func healthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		noRoute(w, r)
		return
	}

	status := struct {
		Status string `json:"status"`
	}{
		Status: fmt.Sprintf("listenning and serving on port %s", port),
	}

	jsonData, err := json.Marshal(status)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	w.Header().Add("Content-Length", fmt.Sprintf("%d", len(jsonData)))
	w.WriteHeader(http.StatusOK)
	w.Write(jsonData)
}

// noRoute is a handle funtion for undefined paths.
func noRoute(w http.ResponseWriter, r *http.Request) {
	status := struct {
		Status string `json:"status"`
	}{
		Status: fmt.Sprintf("not found [%s] %s", r.Method, r.URL),
	}

	jsonData, err := json.Marshal(status)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	w.Header().Add("Content-Length", fmt.Sprintf("%d", len(jsonData)))
	w.WriteHeader(http.StatusNotFound)
	w.Write(jsonData)
}
