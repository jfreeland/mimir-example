package main

import (
	"bytes"
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/golang/snappy"
	"github.com/prometheus/prometheus/prompb"
)

func main() {
	value := flag.Float64("value", 3, "metric value to push")
	interval := flag.Duration("interval", 1*time.Minute, "push interval")
	flag.Parse()

	url := os.Getenv("MIMIR_ADDRESS") + "/push"
	tenantID := os.Getenv("MIMIR_TENANT_ID")
	username := os.Getenv("MIMIR_USERNAME")
	apiToken := os.Getenv("MIMIR_ACCESS_TOKEN")

	ticker := time.NewTicker(*interval)
	defer ticker.Stop()

	for {
		ts := prompb.TimeSeries{
			Labels: []prompb.Label{
				{Name: "__name__", Value: "mimirtool_test_metric"},
				{Name: "test", Value: "nested_folders"},
			},
			Samples: []prompb.Sample{
				{Value: *value, Timestamp: time.Now().UnixMilli()},
			},
		}

		req := &prompb.WriteRequest{
			Timeseries: []prompb.TimeSeries{ts},
		}

		data, err := req.Marshal()
		if err != nil {
			fmt.Println("Marshal error:", err)
			time.Sleep(10 * time.Second)
			continue
		}

		compressed := snappy.Encode(nil, data)

		httpReq, err := http.NewRequest("POST", url, bytes.NewReader(compressed))
		if err != nil {
			fmt.Println("Request error:", err)
			time.Sleep(10 * time.Second)
			continue
		}

		httpReq.Header.Set("Content-Type", "application/x-protobuf")
		httpReq.Header.Set("X-Scope-OrgID", tenantID)
		httpReq.Header.Set("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(username+":"+apiToken)))

		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(httpReq)
		if err != nil {
			fmt.Println("Do error:", err)
			time.Sleep(10 * time.Second)
			continue
		}

		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode == 200 {
			fmt.Println(time.Now().Format("15:04:05"), "✓ Pushed metric")
		} else {
			fmt.Println(time.Now().Format("15:04:05"), "✗ Error:", resp.Status, string(body))
		}

		<-ticker.C
	}
}
