# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready =>
  tripId = ''
  startingPoint = {}
  isOwner = false
  map = null

  
  makeNum = (arr) ->
    arr.forEach (arr) ->
      arr.lat = Number(arr.lat)
      arr.lng = Number(arr.lng)
      return
    arr
  
  
  saveTrip = (positionData) ->
    isOwner = true
    token = $('meta[name="csrf-token"]').attr('content')
    $.ajax
      url: '/trips'
      type: 'post'
      beforeSend: (xhr) ->
        xhr.setRequestHeader 'X-CSRF-Token', token
        return
      data: positionData
      success: (response) ->
        tripId = response.id
        url = """#{window.location.protocol}//#{window.location.host}/trips/#{response.uuid}"""
        initMap()
        $('.name-form').addClass('collapse')
        $('.share-url').append """
          <h6 class="m-0 text-center">Hello <strong>#{response.name}</strong>, here's your location sharing link: <a href="#{url}">#{url}</a></h6>
        """
        getCurrentLocation()
        return
    return
  
  
  getLocation = (name) ->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition (position) ->
        coord = position.coords
        timestamp = position.timestamp
        data =
          lat: coord.latitude,
          lng: coord.longitude,
          name: name
        startingPoint = data
        saveTrip data
    return
  
  
  initMap = ->
    center = 
      lat: startingPoint.lat
      lng: startingPoint.lng
    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: 18
      center: center)
    marker = new (google.maps.Marker)(
      position: center
      map: map)
    return
  
  
  updateMap = (checkin) ->
    lastCheckin = checkin[checkin.length - 1]
    center = 
      lat: startingPoint.lat
      lng: startingPoint.lng
    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: 18
      center: center)
    marker = new (google.maps.Marker)(
      position: lastCheckin
      map: map)
    flightPath = new (google.maps.Polyline)(
      path: checkin
      strokeColor: '#FF0000'
      strokeOpacity: 1.0
      strokeWeight: 2)
    flightPath.setMap map
    

    if isOwner
      setTimeout(getCurrentLocation, 5000)
    return
  
  
  updateCurrentLocation = (tripData, id) ->
    token = $('meta[name="csrf-token"]').attr('content')
    $.ajax
      url: "/trips/#{id}/checkins"
      type: 'post'
      beforeSend: (xhr) ->
        xhr.setRequestHeader 'X-CSRF-Token', token
        return
      data: tripData
      success: (response) ->
        return
    return
  
  
  getCurrentLocation = ->
    navigator.geolocation.getCurrentPosition (position) ->
      data =
        lat: position.coords.latitude,
        lng: position.coords.longitude
      updateCurrentLocation(data, tripId)
    return

  
  unless location.pathname.startsWith('/trips')
    $('.name-form').on 'submit', (event) ->
      event.preventDefault()
      formData = $(this).serialize()
      name = formData.split('=')[1]
      data = getLocation(name)
      return
  
  
  if location.pathname.startsWith('/trips')
    showLat = $('#lat').val()
    showLng = $('#lng').val()
    data =
      lat: Number(showLat),
      lng: Number(showLng)
    startingPoint = data
    initMap()
    
  
  pusher = new Pusher('<%= ENV["PUSHER_KEY"] %>',
    cluster: '<%= ENV["PUSHER_CLUSTER"] %>'
    encrypted: true)
  channel = pusher.subscribe('location')
  channel.bind 'new', (data) ->
    updateMap makeNum(data.checkins)
    return
  return