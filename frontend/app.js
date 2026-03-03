// Your API Gateway URL
const API_URL = "https://fn7s5qprh4.execute-api.us-west-2.amazonaws.com/prod/movers";

// Grab DOM elements
const loading = document.getElementById("loading");
const error = document.getElementById("error");
const table = document.getElementById("movers-table");
const tbody = document.getElementById("movers-body");

// Fetch data from API when page loads
async function fetchMovers() {
    try {
        const response = await fetch(API_URL);

        // Check if the response was successful
        if (!response.ok) {
            throw new Error(`API returned status ${response.status}`);
        }

        const data = await response.json();

        // Hide loading indicator
        loading.classList.add("hidden");

        // If no data yet show a message
        if (data.length === 0) {
            loading.classList.remove("hidden");
            loading.textContent = "No data yet — check back after market close today.";
            return;
        }

        // Build table rows
        data.forEach(item => {
            const row = document.createElement("tr");
            const isGain = item.pct_change >= 0;

            // Color code the row green for gain red for loss
            row.classList.add(isGain ? "gain" : "loss");

            const arrow = isGain ? "▲" : "▼";
            const sign = isGain ? "+" : "";

            row.innerHTML = `
                <td>${formatDate(item.date)}</td>
                <td><span class="ticker-symbol">${item.ticker}</span></td>
                <td><span class="pct-change">${arrow} ${sign}${item.pct_change.toFixed(2)}%</span></td>
                <td><span class="close-price">$${parseFloat(item.close_price).toFixed(2)}</span></td>
            `;

            tbody.appendChild(row);
        });

        // Show the table
        table.classList.remove("hidden");

    } catch (err) {
        // Hide loading show error message
        loading.classList.add("hidden");
        error.classList.remove("hidden");
        console.error("Error fetching movers:", err);
    }
}

// Format date from 2026-03-02 to Mar 2, 2026
function formatDate(dateStr) {
    const date = new Date(dateStr + "T00:00:00");
    return date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric"
    });
}

// Run on page load
fetchMovers();