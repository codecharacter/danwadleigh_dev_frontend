fetch('https://danwadleigh.dev/api/visits')
  .then(response => response.json())
  .then((data) => {
    document.getElementById('views').innerHTML = data
    console.log(data)
  })
  .catch((error) => {
    console.error("Error fetching visitor count:", error)
  })
  